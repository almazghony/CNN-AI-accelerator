module tb_top_uvm;
    `include "uvm_macros.svh"
    `include "conv_pkg_uvm.sv"
    
    import uvm_pkg::*;
    import conv_pkg::*;

    logic clk = 0;
    always #5 clk = ~clk; // 100 MHz

    conv_if vif(clk);

    top dut (
        .clk              (clk),
        .rst_n            (vif.rst_n),
        .start            (vif.start),
        .done             (vif.done),
        .busy             (vif.busy),
        .kernel_we        (vif.kernel_we),
        .kernel_addr      (vif.kernel_addr),
        .kernel_data      (vif.kernel_data),
        .pixel_in         (vif.pixel_in),
        .pixel_valid      (vif.pixel_valid),
        .pixel_out        (vif.pixel_out),
        .pixel_out_valid  (vif.pixel_out_valid)
    );

    initial begin
        uvm_config_db#(virtual conv_if)::set(null, "*", "vif", vif);
        run_test();
    end
endmodule
