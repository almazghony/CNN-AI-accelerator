// conv_sequences.sv — stimulus sequences for the basic env.
`ifndef CONV_SEQUENCES_SV
`define CONV_SEQUENCES_SV

// Base: helpers to build TXN streams (reset / program / start / pixels / wait).
class conv_base_seq extends uvm_sequence #(conv_seq_item);
    `uvm_object_utils(conv_base_seq)

    // frame data chosen by child classes
    bit signed [7:0] kernel [9];   // K_DIM*K_DIM = 9 for K_DIM=3
    bit [7:0]        image [32][32]; // IMG_MAX 32x32
    int              img_h = 32;
    int              img_w = 32;

    function new(string name = "conv_base_seq");
        super.new(name);
    endfunction

    task do_reset(int cycles = 5);
        conv_seq_item t = conv_seq_item::type_id::create("t_rst");
        start_item(t);
        t.kind = TX_RESET;
        t.idle_cycles = cycles;
        finish_item(t);
    endtask

    task program_kernel();
        foreach (kernel[i]) begin
            conv_seq_item t = conv_seq_item::type_id::create("t_k");
            start_item(t);
            t.kind      = TX_PROG_KERNEL;
            t.kern_addr = i;
            t.kern_data = kernel[i];
            finish_item(t);
        end
    endtask

    task pulse_start();
        conv_seq_item t = conv_seq_item::type_id::create("t_start");
        start_item(t);
        t.kind = TX_START;
        finish_item(t);
    endtask

    task stream_image(int idle_max = 0);
        for (int r = 0; r < img_h; r++) begin
            for (int c = 0; c < img_w; c++) begin
                conv_seq_item t = conv_seq_item::type_id::create("t_px");
                // randomize ONLY the gap field, before start_item (UVM rule:
                // no randomization after start_item). Image data comes from image[][].
                if (!t.randomize(idle_cycles))
                    `uvm_fatal("SEQ","randomize idle failed")
                t.kind  = TX_PIXEL;
                t.pixel = image[r][c];
                if (idle_max == 0) t.idle_cycles = 0;
                else t.idle_cycles = t.idle_cycles % (idle_max+1);
                start_item(t);
                finish_item(t);
            end
        end
    endtask

    task wait_done();
        conv_seq_item t = conv_seq_item::type_id::create("t_wd");
        start_item(t);
        t.kind = TX_WAIT_DONE;
        finish_item(t);
    endtask
endclass

// 1) Identity kernel + ramp image (same as tb_top smoke test)
class conv_identity_seq extends conv_base_seq;
    `uvm_object_utils(conv_identity_seq)
    function new(string name="conv_identity_seq"); super.new(name); endfunction
    task body();
        // identity kernel: center = 1
        foreach (kernel[i]) kernel[i] = (i == 4) ? 8'sd1 : 8'sd0;
        // ramp image
        for (int r = 0; r < 32; r++)
            for (int c = 0; c < 32; c++)
                image[r][c] = (r*32 + c) % 256;
        do_reset(5);
        program_kernel();
        pulse_start();
        stream_image(0); // back-to-back
        wait_done();
    endtask
endclass

// 2) Random kernel + random image
class conv_random_seq extends conv_base_seq;
    `uvm_object_utils(conv_random_seq)
    rand bit signed [7:0] k_tmp[9];
    function new(string name="conv_random_seq"); super.new(name); endfunction
    task body();
        if (!randomize(k_tmp)) `uvm_fatal("SEQ","rand kernel failed")
        foreach (kernel[i]) kernel[i] = k_tmp[i];
        for (int r = 0; r < 32; r++)
            for (int c = 0; c < 32; c++)
                image[r][c] = $urandom_range(0,255);
        do_reset(5);
        program_kernel();
        pulse_start();
        stream_image(2); // small random gaps
        wait_done();
    endtask
endclass

// 3) All-ones blur kernel + ramp (checks accumulation path)
class conv_blur_seq extends conv_base_seq;
    `uvm_object_utils(conv_blur_seq)
    function new(string name="conv_blur_seq"); super.new(name); endfunction
    task body();
        foreach (kernel[i]) kernel[i] = 8'sd1;
        for (int r = 0; r < 32; r++)
            for (int c = 0; c < 32; c++)
                image[r][c] = (r*32 + c) % 256;
        do_reset(5);
        program_kernel();
        pulse_start();
        stream_image(0);
        wait_done();
    endtask
endclass

`endif
