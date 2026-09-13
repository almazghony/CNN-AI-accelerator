`ifndef CONV_MULTI_RANDOM_TEST
    `define CONV_MULTI_RANDOM_TEST

// run N random frames in one sim. NOTE: each frame resets the DUT
// (do_reset) because RTL kernel writes are ignored while processing_en and the
// scoreboard frames on the done pulse.
    class conv_multi_random_test extends conv_base_test;
        `uvm_component_utils(conv_multi_random_test)


        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        task run_seq();
            int n_frames = 10;
            string s_val;
            
            super.run_seq();
            if ($value$plusargs("N_FRAMES=%s", s_val))
                n_frames = s_val.atoi();
            `uvm_info("TEST", $sformatf("conv_multi_random_test: sending %0d frames (+N_FRAMES=n to override)", n_frames), UVM_LOW)
            repeat (n_frames) begin
                conv_random_seq s = conv_random_seq::type_id::create("s");
                s.start(env.agt.sqr);
            end
        endtask
    endclass

`endif
