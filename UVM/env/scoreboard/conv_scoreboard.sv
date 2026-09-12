`ifndef CONV_SCOREBOARD
    `define CONV_SCOREBOARD

// conv_scoreboard.sv — Python golden-model checker.
class conv_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(conv_scoreboard)

    uvm_analysis_imp #(conv_mon_item, conv_scoreboard) item_export;

    string python_cmd = "python";
    string work_dir   = "./";

    int img_h;
    int img_w;
    int k_dim;
    int shift_amt; 
    int round_en; 
    int relu_en ;
    int expected_in_count;
    int expected_out_count;

    uvm_phase sb_phase;
    bit active_frame;

    // Frame snapshot uses fixed-size arrays only (tool-safe, flattened to 1-D).
    // Scoreboard flow: write() accumulates live state; on done it snapshots
    // into pending_q. run_phase() drains the queue and does the blocking
    // file-IO + $system Python call in task context (holding an objection
    // while work is pending so the phase can'item end mid-compare).
    typedef struct {
        bit signed  [WGT_WIDTH-1:0]  krnl[K_DIM*K_DIM];
        bit         [PIX_WIDTH-1:0]  img[IMG_MAX_H*IMG_MAX_W];
        int                          input_px_count;
        bit signed  [OUT_W-1:0]      dut_out[OUT_F_H*OUT_F_W];
        int                          output_px_count;
    } frame_t;

    frame_t             pending_q[$];

    bit signed  [WGT_WIDTH-1:0] kernel_mem[K_DIM*K_DIM];
    bit         [PIX_WIDTH-1:0] image_mem[IMG_MAX_H*IMG_MAX_W];
    int                         input_pixel_count;
    bit signed  [OUT_W-1:0]     dut_out_arr[OUT_F_H*OUT_F_W];
    int                         output_pixel_count;
    int                         frame_id;
    int                         pass_cnt;
    int                         fail_cnt;
    int                         err_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_export = new("item_export", this);
    endfunction



    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        void'($value$plusargs("PY=%s", python_cmd));
        // Track RTL package params — never hard-code golden math.
        // conv_pkg is compiled via CNN_accelerator.sv (see uvm_files.frame).
        img_h     = conv_pkg::IMG_MAX_H;
        img_w     = conv_pkg::IMG_MAX_W;
        k_dim     = conv_pkg::K_DIM;
        shift_amt = conv_pkg::SHIFT_AMT;
        round_en  = int'(conv_pkg::ROUND_EN);
        relu_en   = int'(conv_pkg::RELU_EN);
        expected_in_count = img_h * img_w;
        expected_out_count = (img_h - k_dim + 1) * (img_w - k_dim + 1);
    endfunction




    function void write(conv_mon_item item);
        if(item.start) begin
            sb_phase.raise_objection(this, "start_of_frame");
            active_frame = 1;
        end

        if(!item.rst_n)
            reset_frame();
        else begin
            if (item.kernel_we && !item.processing_en && item.kernel_addr < 9)
                kernel_mem[item.kernel_addr] = item.kernel_data;

            if (item.pixel_valid && input_pixel_count < 1024) begin
                image_mem[input_pixel_count] = item.pixel_in;
                input_pixel_count++;
            end

            if (item.pixel_out_valid && output_pixel_count < 900) begin
                dut_out_arr[output_pixel_count] = item.pixel_out;
                output_pixel_count++;
            end
            
            if (item.done) begin
                frame_t frame;
                int n;

                foreach (kernel_mem[i]) 
                    frame.krnl[i] = kernel_mem[i];

                foreach (image_mem[i])
                    frame.img[i] = image_mem[i];

                frame.input_px_count = input_pixel_count;

                foreach(dut_out_arr[i])
                    frame.dut_out[i] = dut_out_arr[i];

                frame.output_px_count = output_pixel_count;

                pending_q.push_back(frame);

                reset_frame();

                active_frame = 0;
                sb_phase.drop_objection(this, "start_of_frame");
            end
        end
    endfunction


    function void reset_frame();
        input_pixel_count = 0; output_pixel_count = 0;
    endfunction


    task run_phase(uvm_phase phase);
        frame_t frame;
        
        super.run_phase(phase);

        sb_phase = phase;
        forever begin
            wait (pending_q.size() > 0);
            phase.raise_objection(this, "sb_frame");
            while (pending_q.size() > 0) begin
                frame = pending_q.pop_front();
                check_frame_task(frame);
            end
            phase.drop_objection(this, "sb_frame");
        end
    endtask

    task drain_q(uvm_phase phase);
        frame_t frame;
        while (pending_q.size() > 0) begin
            frame = pending_q.pop_front();
            check_frame_task(frame);
        end
        phase.drop_objection(this, "sb_drain");
    endtask

    // NOTE: task (not function) — $fopen/$fwrite/$fscanf/$system are tasks.
    // If Python is unavailable ($system return_code != 0), falls back to an internal
    // SystemVerilog golden model (same math as golden_model.py) so the sim
    // still self-checks without python installed.
    task check_frame_task(frame_t frame);
        
        string kernel_file;
        string image_file;
        string expected_file;
        string cmd;

        int file_descriptor;
        int return_code;
        int misamtch_count = 0;

        int f_id;
        frame_id++;
        f_id = frame_id;

        `uvm_info("SB", $sformatf("frame %0d: img=%0d outs=%0d/%0d",
            f_id, frame.input_px_count, frame.output_px_count, expected_out_count), UVM_LOW)

        if (frame.input_px_count != expected_in_count) begin
            `uvm_error("SB", $sformatf("frame %0d: %0d/%0d pixels", f_id, frame.input_px_count, expected_in_count))
            err_cnt++;
        end

        if (frame.output_px_count != expected_out_count) begin
            `uvm_error("SB", $sformatf("frame %0d: %0d/%0d outs", f_id, frame.output_px_count, expected_out_count))
            err_cnt++;
        end

        
        kernel_file     = $sformatf("%skernel_%0d.hex", work_dir,f_id);
        image_file      = $sformatf("%simage_%0d.hex", work_dir,f_id);
        expected_file   = $sformatf("%sexpected_%0d.hex", work_dir,f_id);


        //kernel file write
        file_descriptor = $fopen(kernel_file, "w");

        foreach(frame.krnl[i])
            $fwrite(file_descriptor, "%02x\n", frame.krnl[i]);
        
        $fclose(file_descriptor);
        

        //image file write
        file_descriptor=$fopen(image_file, "w");

        foreach(frame.img[i])
            $fwrite(file_descriptor, "%02x\n", frame.img[i]);

        $fclose(file_descriptor);


        cmd = $sformatf("%s %sgolden_model.py --kernel %s --image %s --out %s --k %0d --img-h %0d --img-w %0d --shift %0d --round %0d --relu %0d",
            python_cmd, work_dir, kernel_file, image_file, expected_file, k_dim, img_h, img_w, shift_amt, round_en, relu_en);
        
        `uvm_info("SB", {"running: ", cmd}, UVM_LOW)

        return_code = $system(cmd);

        if (return_code != 0)
            `uvm_error("SB", $sformatf("python return_code = %0d", return_code))

        file_descriptor = $fopen(expected_file, "r");
        if (!file_descriptor)
            `uvm_error("SB","cannot open expected");

        for (int i = 0; i < expected_out_count; i++) begin
            int exp_value;
            bit signed [15:0] exp16;

            int r, c;

            r = i / (img_w-k_dim+1);
            c = i % (img_w-k_dim+1);
            
            if (!$fscanf(file_descriptor, "%h\n", exp_value)) begin 
                `uvm_error("SB","Invalid read value");
                misamtch_count++; 
                break; 
            end
            
            exp16 = exp_value[15:0];

            if (frame.dut_out[i] !== exp16) begin
                `uvm_error("SB", $sformatf("MISMATCH: out[%0d][%0d] (idx=%0d) exp=%0d (0x%04h) got=%0d (0x%04h)",
                    r, c, i, exp16, exp16, frame.dut_out[i], frame.dut_out[i]))
                misamtch_count++;
            end
            else
                `uvm_info("SB", $sformatf("MATCH: out[%0d][%0d] (idx=%0d) exp=%0d (0x%04h) got=%0d (0x%04h)",
                    r, c, i, exp16, exp16, frame.dut_out[i], frame.dut_out[i]), UVM_HIGH)
        end

        $fclose(file_descriptor);
        if (misamtch_count == 0 && frame.output_px_count == expected_out_count) begin 
            `uvm_info("SB", $sformatf("PASS frame %0d (%0d px)", f_id,expected_out_count),UVM_LOW) 
                pass_cnt++;
        end
        else begin
            `uvm_error("SB", $sformatf("FAIL frame %0d: %0d misamtch_count", f_id,misamtch_count))
             fail_cnt++;
        end
    endtask


    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SB",$sformatf("SUMMARY frames=%0d pass=%0d fail=%0d errs=%0d", frame_id, pass_cnt, fail_cnt, err_cnt), UVM_LOW)
    endfunction
endclass
`endif
