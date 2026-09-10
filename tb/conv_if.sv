// conv_if.sv — UVM interface for CNN accelerator `top`
// Basic, single-interface version: driver + monitors share one vif.
interface conv_if (input logic clk);
    import conv_pkg::*;

    logic                          rst_n;
    logic                          start;
    logic                          done;
    logic                          busy;
    logic                          kernel_we;
    logic [K_ADDR_W-1:0]           kernel_addr;
    logic [WGT_WIDTH-1:0]          kernel_data;
    logic [PIX_WIDTH-1:0]          pixel_in;
    logic                          pixel_valid;
    logic signed [OUT_W-1:0]       pixel_out;
    logic                          pixel_out_valid;

    // Clocking blocks help avoid races when driving on posedge.
    // The driver in this basic env drives on negedge directly, so these
    // are mainly for the monitors (sample on posedge).
    clocking mon_cb @(posedge clk);
        input rst_n, start, done, busy;
        input kernel_we, kernel_addr, kernel_data;
        input pixel_in, pixel_valid;
        input pixel_out, pixel_out_valid;
    endclocking

    modport DRV (
        input  clk, done, busy, pixel_out, pixel_out_valid,
        output rst_n, start, kernel_we, kernel_addr, kernel_data,
               pixel_in, pixel_valid
    );

    modport MON (
        input clk, rst_n, start, done, busy,
              kernel_we, kernel_addr, kernel_data,
              pixel_in, pixel_valid,
              pixel_out, pixel_out_valid
    );
endinterface
