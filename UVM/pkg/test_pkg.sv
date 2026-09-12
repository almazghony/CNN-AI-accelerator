
`include "shared_pkg.sv"
`include "env_pkg.sv"

package test_pkg;
    import uvm_pkg::*;
    import env_pkg::*;
    import agent_pkg::*;
    import shared_pkg::*;
    
    `include "../sequences/conv_base_seq.sv"
    `include "../sequences/conv_identity_seq.sv"
    `include "../sequences/conv_random_seq.sv"
    `include "../sequences/conv_blur_seq.sv"
    `include "../tests/conv_base_test.sv"
    `include "../tests/conv_blur_test.sv"
    `include "../tests/conv_identity_test.sv"
    `include "../tests/conv_random_test.sv"
    `include "../tests/conv_multi_random_test.sv"

endpackage