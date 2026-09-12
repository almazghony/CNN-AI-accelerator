`ifndef CONV_RANDOM_TEST
    `define CONV_RANDOM_TEST

    class conv_random_test extends conv_base_test;
        `uvm_component_utils(conv_random_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction


        task run_seq();
            conv_random_seq s = conv_random_seq::type_id::create("s");
            s.start(env.agt.sqr);
        endtask
    endclass

`endif