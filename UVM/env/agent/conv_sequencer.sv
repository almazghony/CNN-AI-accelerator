`ifndef CONV_SEQUENCER
    `define CONV_SEQUENCER

    class conv_sequencer extends uvm_sequencer#(conv_drv_item);
        `uvm_component_utils(conv_sequencer)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

    endclass

`endif