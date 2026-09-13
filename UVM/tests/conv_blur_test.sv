`ifndef CONV_BLUR_TEST
    `define CONV_BLUR_TEST
    
    class conv_blur_test extends conv_base_test;
        `uvm_component_utils(conv_blur_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction


        task run_seq();
            conv_blur_seq s = conv_blur_seq::type_id::create("s");
            super.run_seq();
            s.start(env.agt.sqr);
        endtask

    endclass

`endif