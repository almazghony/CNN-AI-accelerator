`ifndef CONV_IF
    `define CONV_IF

    // conv_if.sv — UVM interface for CNN accelerator `top`
    // Basic, single-interface version: driver + monitors share one vif.
    interface conv_if (input logic clk);
        import conv_pkg::*;

        logic                          rst_n;
        logic                          start;
        logic                          done;
        logic                          processing_en;
        logic                          kernel_we;
        logic [K_ADDR_W-1:0]           kernel_addr;
        logic [WGT_WIDTH-1:0]          kernel_data;
        logic [PIX_WIDTH-1:0]          pixel_in;
        logic                          pixel_valid;
        logic signed [OUT_W-1:0]       pixel_out;
        logic                          pixel_out_valid;

        // Clocking blocks avoid races: drv_cb drives (output skew 0) are
        // applied at the posedge, mon_cb samples (default input skew 1step)
        // capture the pre-edge values the DUT sees at that same posedge.
        clocking mon_cb @(posedge clk);
            input rst_n;
            input start;
            input done;
            input processing_en;
            input kernel_we;
            input kernel_addr;
            input kernel_data;
            input pixel_in;
            input pixel_valid;
            input pixel_out;
            input pixel_out_valid;
        endclocking

        clocking drv_cb @(posedge clk);
            output rst_n;
            output start;
            output kernel_we;
            output kernel_addr;
            output kernel_data;
            output pixel_in;
            output pixel_valid;
        endclocking

    endinterface
`endif