`ifndef CONV_RESET_SEQ
    `define CONV_RESET_SEQ

    // 2) Random kernel + random image
    class conv_reset_seq extends conv_base_seq;
        `uvm_object_utils(conv_reset_seq)
        


        function new(string name=""); 
            super.new(name); 
        endfunction

        task body();
            do_reset(1);
        endtask
    endclass
    
`endif