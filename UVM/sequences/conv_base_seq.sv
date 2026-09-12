`ifndef CONV_BASE_SEQ
    `define CONV_BASE_SEQ

// Base: helpers to build TXN streams (reset / program / start / pixels / wait).
class conv_base_seq extends uvm_sequence #(conv_drv_item);
    `uvm_object_utils(conv_base_seq)

    // frame data chosen by child classes
    bit signed [7:0] kernel [9];   // K_DIM*K_DIM = 9 for K_DIM=3
    bit [7:0]        image  [32][32]; // IMG_MAX 32x32
    int              img_h = 32;
    int              img_w = 32;

    function new(string name = "conv_base_seq");
        super.new(name);
    endfunction

    task do_reset(int cycles = 5);
        conv_drv_item item = conv_drv_item::type_id::create("t_rst");
        start_item(item);
        item.kind = TX_RESET;
        item.idle_cycles = cycles;
        finish_item(item);
    endtask

    task program_kernel();
        foreach (kernel[i]) begin
            conv_drv_item item = conv_drv_item::type_id::create("t_k");
            start_item(item);
            item.kind      = TX_PROG_KERNEL;
            item.kern_addr = i;
            item.kern_data = kernel[i];
            finish_item(item);
        end
    endtask

    task pulse_start();
        conv_drv_item item = conv_drv_item::type_id::create("t_start");
        start_item(item);
        item.kind = TX_START;
        finish_item(item);
    endtask

    task stream_image(int idle_max = 0);
        for (int r = 0; r < img_h; r++) begin
            for (int c = 0; c < img_w; c++) begin
                conv_drv_item item = conv_drv_item::type_id::create("t_px");
                // randomize ONLY the gap field, before start_item (UVM rule:
                // no randomization after start_item). Image data comes from image[][].
                if (!item.randomize(idle_cycles))
                    `uvm_fatal("SEQ","randomize idle failed")
                item.kind  = TX_PIXEL;
                item.pixel = image[r][c];
                if (idle_max == 0) item.idle_cycles = 0;
                else item.idle_cycles = item.idle_cycles % (idle_max+1);
                start_item(item);
                finish_item(item);
            end
        end
    endtask
endclass

`endif