// conv_agent.sv — 1 sequencer + 1 driver + 1 monitor
`ifndef CONV_AGENT
    `define CONV_AGENT
    class conv_agent extends uvm_agent;
        `uvm_component_utils(conv_agent)

        conv_cfg                            cfg;
        conv_sequencer                      sqr;
        conv_driver                         drv;
        conv_monitor                        mon;
        uvm_analysis_port #(conv_mon_item)  ap;
        virtual conv_if                     vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction


        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(virtual conv_if)::get(this, "", "vif", vif))
                `uvm_fatal("VIF", "vif not set in config_db")
                
            if (!uvm_config_db#(conv_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("CFG", "cfg not set in config_db")
            
            mon = conv_monitor::type_id::create("mon", this);

            if (cfg.is_active == UVM_ACTIVE) begin
                sqr = conv_sequencer::type_id::create("sqr", this);
                drv = conv_driver::type_id::create("drv", this);
            end
        endfunction


        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            
            mon.ap.connect(ap);
            mon.vif = vif;
            if (cfg.is_active == UVM_ACTIVE) begin
                drv.seq_item_port.connect(sqr.seq_item_export);
                drv.vif = vif;
            end
        endfunction
    endclass
`endif
