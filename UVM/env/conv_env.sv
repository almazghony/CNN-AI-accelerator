// conv_env.sv — agent + scoreboard
`ifndef CONV_ENV_
`define CONV_ENV

class conv_env extends uvm_env;
    `uvm_component_utils(conv_env)

    conv_agent      agt;
    conv_scoreboard scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = conv_agent::type_id::create("agt", this);
        scb  = conv_scoreboard::type_id::create("scb", this);
    endfunction

    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.ap.connect(scb.item_export);
    endfunction
endclass
`endif
