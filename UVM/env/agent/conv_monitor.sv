`ifndef CONV_MONITOR
    `define CONV_MONITOR

    class conv_monitor extends uvm_monitor;
        `uvm_component_utils(conv_monitor)

        conv_mon_item item_temp;
        virtual conv_if vif;
        uvm_analysis_port #(conv_mon_item) ap;
        int pixel_in_count;
        int pixel_out_count;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);

        endfunction


        task run_phase(uvm_phase phase);
            conv_mon_item item;
            item_temp = conv_mon_item::type_id::create("item_temp");
            forever begin
                @(vif.mon_cb);
                item_temp.rst_n            <= vif.mon_cb.rst_n;
                item_temp.start            <= vif.mon_cb.start;
                item_temp.kernel_we        <= vif.mon_cb.kernel_we;
                item_temp.kernel_addr      <= vif.mon_cb.kernel_addr;
                item_temp.kernel_data      <= vif.mon_cb.kernel_data;
                item_temp.pixel_in         <= vif.mon_cb.pixel_in;
                item_temp.pixel_valid      <= vif.mon_cb.pixel_valid;
                item_temp.pixel_out        <= vif.mon_cb.pixel_out;
                item_temp.pixel_out_valid  <= vif.mon_cb.pixel_out_valid;
                item_temp.done             <= vif.mon_cb.done;
                item_temp.processing_en             <= vif.mon_cb.processing_en;

                item = conv_mon_item::type_id::create("item");
                item = item_temp;
                
                if (item.pixel_valid)
                    pixel_in_count++;
                if (item.pixel_out_valid)
                    pixel_out_count++;

                `uvm_info("MON", $sformatf("monitoring: %s, Pixel in count: %0d, Pixel out count: %0d", item.convert2string(), pixel_in_count, pixel_out_count), UVM_MEDIUM)
                ap.write(item);
            end
        endtask
    endclass
`endif
