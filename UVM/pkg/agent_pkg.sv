
`include "../env/agent/conv_if.sv"
package agent_pkg;
    import uvm_pkg::*;
    import shared_pkg::*;

    `include "../env/agent/conv_cfg.sv"
    `include "../env/agent/conv_drv_item.sv"
    `include "../env/agent/conv_mon_item.sv"
    `include "../env/agent/conv_sequencer.sv"
    `include "../env/agent/conv_driver.sv"
    `include "../env/agent/conv_monitor.sv"
    `include "../env/agent/conv_agent.sv"

endpackage