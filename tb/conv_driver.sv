`ifndef CONV_DRIVER_SV
`define CONV_DRIVER_SV

class conv_driver extends uvm_driver #(conv_seq_item);
    `uvm_component_utils(conv_driver)
    virtual conv_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    task run_phase(uvm_phase phase);
        vif.rst_n       = 1;
        vif.start       = 0;
        vif.kernel_we   = 0;
        vif.kernel_addr = 0;
        vif.kernel_data = 0;
        vif.pixel_in    = 0;
        vif.pixel_valid = 0;

        forever begin
            conv_seq_item item;
            seq_item_port.get_next_item(item);
            `uvm_info("DRV", {"driving: ", item.convert2string()}, UVM_HIGH)
            
            case (item.kind)
                TX_RESET:       do_reset(item.idle_cycles);
                TX_PROG_KERNEL: do_prog_kernel(item.kern_addr, item.kern_data);
                TX_START:       do_start();
                TX_PIXEL:       do_pixel(item.pixel, item.idle_cycles);
                TX_WAIT_DONE:   do_wait_done();
                TX_IDLE_GAP:    do_idle(item.idle_cycles);

                default: `uvm_error("DRV", "unknown txn kind")
            endcase
            seq_item_port.item_done();
        end
    endtask

    task do_reset(int cycles);
        vif.start       = 1'b0;
        vif.kernel_we   = 1'b0;
        vif.pixel_valid = 1'b0;
        vif.rst_n       = 1'b0;
        repeat (cycles) @(negedge vif.clk);
        vif.rst_n       = 1'b1;
        @(negedge vif.clk);
    endtask

    task do_prog_kernel(int addr, bit [7:0] data);
        @(negedge vif.clk);
        vif.kernel_we   = 1'b1;
        vif.kernel_addr = addr;
        vif.kernel_data = data;
        vif.pixel_valid = 1'b0;
        vif.start       = 1'b0;
        @(negedge vif.clk);
        vif.kernel_we   = 1'b0;
    endtask

    task do_start();
        @(negedge vif.clk);
        vif.kernel_we   = 1'b0;
        vif.pixel_valid = 1'b0;
        vif.start       = 1'b1;
        @(negedge vif.clk);
        vif.start       = 1'b0;
    endtask

    task do_pixel(bit [7:0] px, int idle);
        repeat (idle) begin
            @(negedge vif.clk);
            vif.kernel_we   = 1'b0;
            vif.start       = 1'b0;
            vif.pixel_valid = 1'b0;
        end
        @(negedge vif.clk);
        vif.kernel_we   = 1'b0;
        vif.start       = 1'b0;
        vif.pixel_in    = px;
        vif.pixel_valid = 1'b1;
    endtask

    task do_idle(int cycles);
        repeat (cycles) begin
            @(negedge vif.clk);
            vif.kernel_we   = 1'b0;
            vif.start       = 1'b0;
            vif.pixel_valid = 1'b0;
        end
    endtask

    task do_wait_done();
        @(negedge vif.clk);
        vif.kernel_we   = 1'b0;
        vif.start       = 1'b0;
        vif.pixel_valid = 1'b0;
        fork
            begin wait (vif.done === 1'b1); end
            begin repeat (5000) @(negedge vif.clk); end
        join_any
        disable fork;

        if (vif.done !== 1'b1)
            `uvm_error("DRV", "TIMEOUT waiting for done");
        repeat (3) @(negedge vif.clk);
    endtask
endclass
`endif