`ifndef CONV_CFG
    `define CONV_CFG

    class conv_cfg extends uvm_object;
        `uvm_object_utils(conv_cfg)

        uvm_active_passive_enum  is_active;

        function new(string name="");
            super.new(name);
        endfunction
    endclass

`endif