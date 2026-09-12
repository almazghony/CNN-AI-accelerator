`ifndef CONV_MON_ITEM
    `define CONV_MON_ITEM
    
    class conv_mon_item extends uvm_sequence_item;
        `uvm_object_utils(conv_mon_item)

        // snapshot of one clock's worth of interface activity
        bit                          rst_n;
        bit                          start;
        bit                          kernel_we;
        bit [K_ADDR_W-1:0]           kernel_addr;
        bit [WGT_WIDTH-1:0]          kernel_data;
        bit [PIX_WIDTH-1:0]          pixel_in;
        bit                          pixel_valid;
        bit signed [OUT_W-1:0]       pixel_out;
        bit                          pixel_out_valid;
        bit                          done;
        bit                          processing_en;


        function new(string name = "conv_mon_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf("rst_n=%0b start=%0b kernel_we=%0b kernel_addr=%0d kernel_data=%0h pixel_in=%0d pixel_valid=%0b pixel_out=%0d pixel_out_valid=%0b done=%0b processing_en=%0b",
                rst_n, start, kernel_we, kernel_addr, kernel_data, pixel_in, pixel_valid, pixel_out, pixel_out_valid, done, processing_en);
        endfunction
    endclass
`endif