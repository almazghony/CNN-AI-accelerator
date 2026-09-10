// conv_scoreboard.sv — Python golden-model checker.
// write() snoops pins (function context); run_phase() drains pending_q
// and does file-IO + $system(Python) in task context.
`ifndef CONV_SCOREBOARD_SV
`define CONV_SCOREBOARD_SV

class conv_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(conv_scoreboard)
    uvm_analysis_imp #(conv_mon_tr, conv_scoreboard) item_export;

    string python_cmd = "python";
    string work_dir   = "./";
    int    img_h = 32; int img_w = 32; int k_dim = 3;
    int    shift_amt = 1; int round_en = 1; int relu_en = 1;

    // Frame snapshot uses fixed-size arrays only (tool-safe, flattened to 1-D).
    // Scoreboard flow: write() accumulates live state; on done it snapshots
    // into pending_q. run_phase() drains the queue and does the blocking
    // file-IO + $system Python call in task context (holding an objection
    // while work is pending so the phase can't end mid-compare).
    typedef struct {
        bit signed [7:0] krnl[9];
        bit [7:0]        img[1024];
        int              n_img;
        bit signed [15:0] dut[900];
        int              n_dut;
    } frame_t;
    frame_t pending_q[$];

    bit signed [7:0] kernel_mem[9];
    bit [7:0]  image_mem[1024];
    int img_count;
    bit signed [15:0] dut_out_arr[900];
    int dut_out_count, frame_id, pass_cnt, fail_cnt, err_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_export = new("item_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'($value$plusargs("PY=%s", python_cmd));
    endfunction

    function void write(conv_mon_tr t);
        if (t.rst_n === 1'b0) begin reset_frame(); return; end
        if (t.kernel_we && !t.busy && t.kernel_addr < 9)
            kernel_mem[t.kernel_addr] = t.kernel_data;
        if (t.pixel_valid && t.rst_n && img_count < 1024) begin
            image_mem[img_count] = t.pixel_in;
            img_count++;
        end
        if (t.pixel_out_valid && dut_out_count < 900) begin
            dut_out_arr[dut_out_count] = t.pixel_out;
            dut_out_count++;
        end
        // Snapshot live state into the pending queue for run_phase.
        // No file-IO / $system here (write() is a function).
        if (t.done) begin
            frame_t f;
            int n;
            foreach (kernel_mem[i]) f.krnl[i] = kernel_mem[i];
            for (int i = 0; i < img_count; i++) f.img[i] = image_mem[i];
            f.n_img = img_count;
            n = (dut_out_count < 900) ? dut_out_count : 900;
            for (int i = 0; i < n; i++) f.dut[i] = dut_out_arr[i];
            f.n_dut = dut_out_count;
            pending_q.push_back(f);
            reset_frame();
        end
    endfunction

    function void reset_frame();
        img_count = 0; dut_out_count = 0;
    endfunction

    task run_phase(uvm_phase phase);
        frame_t f;
        forever begin
            // Poll-drain: write() (function context) snapshots frames into
            // pending_q on the done pulse; all blocking file-IO + $system
            // happens here in task context.
            wait (pending_q.size() > 0);
            phase.raise_objection(this, "sb_frame");
            while (pending_q.size() > 0) begin
                f = pending_q.pop_front();
                check_frame_task(f);
            end
            phase.drop_objection(this, "sb_frame");
        end
    endtask

    // NOTE: task (not function) — $fopen/$fwrite/$fscanf/$system are tasks.
    // If Python is unavailable ($system rc != 0), falls back to an internal
    // SystemVerilog golden model (same math as golden_model.py) so the sim
    // still self-checks without python installed.
    task check_frame_task(frame_t f);
        int exp_n = (img_h-k_dim+1)*(img_w-k_dim+1);
        string kf, imf, df, ef, cmd;
        int fd, rc, mism = 0;
        int fid;
        frame_id++;
        fid = frame_id;
        `uvm_info("SB", $sformatf("frame %0d: img=%0d outs=%0d/%0d",
            fid, f.n_img, f.n_dut, exp_n), UVM_LOW)
        if (f.n_img != 1024) begin
            `uvm_error("SB", $sformatf("frame %0d: %0d/1024 pixels", fid, f.n_img))
            err_cnt++;
        end
        if (f.n_dut != exp_n) begin
            `uvm_error("SB", $sformatf("frame %0d: %0d/%0d outs", fid, f.n_dut, exp_n))
            err_cnt++;
        end
        kf=$sformatf("%skernel_%0d.hex",work_dir,fid);
        imf=$sformatf("%simage_%0d.hex",work_dir,fid);
        df=$sformatf("%sdut_out_%0d.hex",work_dir,fid);
        ef=$sformatf("%sexpected_%0d.hex",work_dir,fid);
        fd=$fopen(kf,"w");
        for (int i=0;i<9;i++) $fwrite(fd,"%02x\n",f.krnl[i]&8'hff);
        $fclose(fd);
        fd=$fopen(imf,"w");
        for (int i=0;i<f.n_img;i++) $fwrite(fd,"%02x\n",f.img[i]);
        $fclose(fd);
        fd=$fopen(df,"w");
        for (int i=0;i<f.n_dut;i++) $fwrite(fd,"%04x\n",f.dut[i]&16'hffff);
        $fclose(fd);
        cmd=$sformatf("%s %sgolden_model.py --kernel %s --image %s --out %s",
            python_cmd, work_dir, kf, imf, ef);
        `uvm_info("SB", {"running: ",cmd}, UVM_LOW)
        rc=$system(cmd);
        if (rc!=0) begin
            `uvm_info("SB",$sformatf("python rc=%0d — using internal SV golden model",rc),UVM_LOW)
            check_frame_sv(f, fid, exp_n);
            return;
        end
        fd=$fopen(ef,"r");
        if (fd==0) begin `uvm_error("SB","cannot open expected"); err_cnt++; return; end
        for (int i=0;i<exp_n;i++) begin
            int expv; bit signed [15:0] exp16;
            int r, c;
            r = i / (img_w-k_dim+1);
            c = i % (img_w-k_dim+1);
            if ($fscanf(fd,"%h\n",expv)!=1) begin `uvm_error("SB","expected short"); mism++; break; end
            exp16=expv[15:0];
            if (i<f.n_dut) begin
                if (f.dut[i]!==exp16) begin
                    if(mism<20) begin
                        `uvm_error("SB",$sformatf("MIS out[%0d][%0d] (idx=%0d) exp=%0d (0x%04h) got=%0d (0x%04h)",
                            r, c, i, exp16, exp16&16'hffff, f.dut[i], f.dut[i]&16'hffff))
                    end
                    mism++;
                end
            end else mism++;
        end
        $fclose(fd);
        if (mism==0 && f.n_dut==exp_n) begin `uvm_info("SB",$sformatf("PASS frame %0d (%0d px)",fid,exp_n),UVM_LOW) pass_cnt++; end
        else begin `uvm_error("SB",$sformatf("FAIL frame %0d: %0d mism",fid,mism)) fail_cnt++; end
    endtask

    // Internal SV golden model: valid KxK conv (stride 1) -> ReLU ->
    // round+shift (>>> arithmetic) -> sat to s16. Mirrors golden_model.py.
    function void check_frame_sv(frame_t f, int fid, int exp_n);
        int mism = 0;
        int OW = img_w - k_dim + 1;
        for (int i = 0; i < exp_n; i++) begin
            int r, c;
            int acc;
            bit signed [15:0] exp16;
            r = i / OW;
            c = i % OW;
            acc = 0;
            for (int kr = 0; kr < k_dim; kr++)
                for (int kc = 0; kc < k_dim; kc++)
                    acc += int'(f.img[(r+kr)*img_w + (c+kc)]) * int'(f.krnl[kr*k_dim + kc]);
            if (relu_en && acc < 0) acc = 0;
            if (round_en && shift_amt != 0) acc = acc + (1 << (shift_amt-1));
            if (shift_amt != 0) acc = acc >>> shift_amt; // arithmetic
            if (acc > 32767) acc = 32767;
            else if (acc < -32768) acc = -32768;
            exp16 = acc[15:0];
            if (i < f.n_dut) begin
                if (f.dut[i] !== exp16) begin
                    if (mism < 20) begin
                        `uvm_error("SB",$sformatf("MIS(SV) out[%0d][%0d] (idx=%0d) exp=%0d (0x%04h) got=%0d (0x%04h)",
                            r, c, i, exp16, exp16&16'hffff, f.dut[i], f.dut[i]&16'hffff))
                    end
                    mism++;
                end
            end else mism++;
        end
        if (mism == 0 && f.n_dut == exp_n) begin `uvm_info("SB",$sformatf("PASS(SV) frame %0d (%0d px)",fid,exp_n),UVM_LOW) pass_cnt++; end
        else begin `uvm_error("SB",$sformatf("FAIL(SV) frame %0d: %0d mism",fid,mism)) fail_cnt++; end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SB",$sformatf("SUMMARY frames=%0d pass=%0d fail=%0d errs=%0d",frame_id,pass_cnt,fail_cnt,err_cnt),UVM_LOW)
    endfunction
endclass
`endif
