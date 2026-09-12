
`include "agent_pkg.sv"

package env_pkg;
    import uvm_pkg::*;
    import agent_pkg::*;
    import shared_pkg::*;

    `include "../env/scoreboard/conv_scoreboard.sv"
    `include "../env/conv_env.sv"
endpackage