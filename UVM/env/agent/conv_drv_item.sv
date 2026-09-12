`ifndef CONV_DRV_ITEM
    `define CONV_DRV_ITEM


    class conv_drv_item extends uvm_sequence_item;
        `uvm_object_utils(conv_drv_item)

        rand conv_txn_e   kind;

        // Used when kind == TX_PROG_KERNEL
        rand bit [7:0]    kern_data;
        int               kern_addr;

        // Used when kind == TX_PIXEL
        rand bit [7:0]    pixel;
        rand int          idle_cycles; // gap before this pixel (for backpressure-ish tests)


        constraint c_idle {
            idle_cycles inside {[0:5]}; 
            
        }


        function new(string name="");
            super.new(name);
        endfunction


        function string convert2string();
            return $sformatf("kind=%s addr=%0d kdata=%0h pixel=%0d idle=%0d",
                kind.name(), kern_addr, kern_data, pixel, idle_cycles);
        endfunction
    endclass
`endif
