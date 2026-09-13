`ifndef CONV_DRIVER
    `define CONV_DRIVER

    class conv_driver extends uvm_driver #(conv_drv_item);
        `uvm_component_utils(conv_driver)
        virtual conv_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction


        task run_phase(uvm_phase phase);
            vif.drv_cb.rst_n       <= 1;
            vif.drv_cb.start       <= 0;
            vif.drv_cb.kernel_we   <= 0;
            vif.drv_cb.kernel_addr <= 0;
            vif.drv_cb.kernel_data <= 0;
            vif.drv_cb.pixel_in    <= 0;
            vif.drv_cb.pixel_valid <= 0;

            forever begin
                conv_drv_item item;
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
            vif.drv_cb.start       <= 1'b0;
            vif.drv_cb.kernel_we   <= 1'b0;
            vif.drv_cb.pixel_valid <= 1'b0;
            vif.drv_cb.rst_n       <= 1'b0;
            @(vif.drv_cb);
            repeat (cycles) @(vif.drv_cb);
            vif.drv_cb.rst_n       <= 1'b1;
            @(vif.drv_cb);
        endtask

        task do_prog_kernel(int addr, bit [7:0] data);
            vif.drv_cb.kernel_we   <= 1'b1;
            vif.drv_cb.kernel_addr <= addr;
            vif.drv_cb.kernel_data <= data;
            vif.drv_cb.pixel_valid <= 1'b0;
            vif.drv_cb.start       <= 1'b0;
            @(vif.drv_cb);
            vif.drv_cb.kernel_we   <= 1'b0;
        endtask

        task do_start();
            vif.drv_cb.kernel_we   <= 1'b0;
            vif.drv_cb.pixel_valid <= 1'b0;
            vif.drv_cb.start       <= 1'b1;
            @(vif.drv_cb);
            vif.drv_cb.start       <= 1'b0;
        endtask

        task do_pixel(bit [7:0] px, int idle);
            repeat (idle) begin
                vif.drv_cb.kernel_we   <= 1'b0;
                vif.drv_cb.start       <= 1'b0;
                vif.drv_cb.pixel_valid <= 1'b0;
                @(vif.drv_cb);
            end
            vif.drv_cb.kernel_we   <= 1'b0;
            vif.drv_cb.start       <= 1'b0;
            vif.drv_cb.pixel_in    <= px;
            vif.drv_cb.pixel_valid <= 1'b1;
            @(vif.drv_cb);
            vif.drv_cb.pixel_valid <= 1'b0;
        endtask

        task do_idle(int cycles);
            repeat (cycles) begin
                vif.drv_cb.kernel_we   <= 1'b0;
                vif.drv_cb.start       <= 1'b0;
                vif.drv_cb.pixel_valid <= 1'b0;
                @(vif.drv_cb);
            end
        endtask


        task do_wait_done();
            vif.kernel_we   = 1'b0;
            vif.start       = 1'b0;
            vif.pixel_valid = 1'b0;
            wait (vif.done === 1'b1);
            @(vif.drv_cb);
        endtask
    endclass
`endif