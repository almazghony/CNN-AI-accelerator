// conv_tests.sv — test list; select with +UVM_TESTNAME=<name>
`ifndef CONV_TESTS_SV
`define CONV_TESTS_SV

class conv_base_test extends uvm_test;
    `uvm_component_utils(conv_base_test)
    conv_env env;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = conv_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        run_seq();
        // No manual drain needed: scoreboard raises its own objection while
        // pending_q is non-empty, so drop here and let UVM end the phase
        // once all checks complete.
        phase.drop_objection(this);
    endtask
    virtual task run_seq();
        `uvm_fatal("TEST", "override run_seq() in child test")
    endtask
endclass

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

class conv_blur_test extends conv_base_test;
    `uvm_component_utils(conv_blur_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    task run_seq();
        conv_blur_seq s = conv_blur_seq::type_id::create("s");
        s.start(env.agt.sqr);
    endtask
endclass

// run N random frames in one sim. NOTE: each frame resets the DUT
// (do_reset) because RTL kernel writes are ignored while busy and the
// scoreboard frames on the done pulse.
class conv_multi_random_test extends conv_base_test;
    `uvm_component_utils(conv_multi_random_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    task run_seq();
        repeat (3) begin
            conv_random_seq s = conv_random_seq::type_id::create("s");
            s.start(env.agt.sqr);
        end
    endtask
endclass

`endif
