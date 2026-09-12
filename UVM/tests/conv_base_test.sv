`ifndef CONV_BASE_TEST
    `define CONV_BASE_TEST

class conv_base_test extends uvm_test;
    `uvm_component_utils(conv_base_test)

    conv_cfg cfg;
    conv_env env;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = conv_cfg::type_id::create("cfg", this);
        env = conv_env::type_id::create("env", this);

        cfg.is_active = UVM_ACTIVE;

        uvm_config_db#(conv_cfg)::set(this, "env.agt", "cfg", cfg);
    endfunction

    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
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

`endif