`ifndef CONV_IDENTITY_TEST
    `define CONV_IDENTITY_TEST

    class conv_identity_test extends conv_base_test;
        `uvm_component_utils(conv_identity_test)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction


        task run_seq();
            conv_identity_seq s = conv_identity_seq::type_id::create("s");
            s.start(env.agt.sqr);
        endtask
    endclass

`endif