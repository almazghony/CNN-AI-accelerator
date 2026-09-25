module top
    import conv_pkg::*;

(
    input  logic                            clk,
    input  logic                            rst_n,

    input  logic                            start,
    output logic                            done,
    output logic                            processing_en,

    input  logic                            kernel_we,
    input  logic [K_ADDR_W-1:0]             kernel_addr,
    input  logic [WGT_WIDTH-1:0]            kernel_data,

    input  logic [PIX_WIDTH-1:0]            pixel_in,
    input  logic                            pixel_valid,

    output logic signed [OUT_W-1:0]         pixel_out,
    output logic                            pixel_out_valid
);

    // ---------------------------------------------------------------------
    // Internal wires
    // ---------------------------------------------------------------------
    logic                           output_done;     

    logic [PIX_WIDTH-1:0]           ctrl_pixel_out;  
    logic                           ctrl_pixel_valid;

    logic [PIX_WIDTH-1:0]           window [K_DIM*K_DIM];
    logic                           window_valid;
    logic                           end_of_row;
    logic                           end_of_frame;

    logic signed [WGT_WIDTH-1:0]    kernel_coeffs [K_DIM*K_DIM];

    logic signed [ACC_W-1:0]        conv_result;
    logic                           conv_valid;

    logic signed [ACC_W-1:0]        relu_result;
    logic                           relu_valid;

    logic [OUT_W-1:0]               fmt_pixel_out;
    logic                           fmt_pixel_valid;

    // ---------------------------------------------------------------------
    // Module instantiations
    // ---------------------------------------------------------------------

    // 1. Global controller
    global_ctrl u_global_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .output_done    (output_done),
        .done           (done),
        .processing_en  (processing_en)
    );

    // 2. Input controller (streaming handshake + row/frame counters)
    input_ctrl u_input_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .processing_en  (processing_en),
        .pixel_in       (pixel_in),
        .pixel_valid    (pixel_valid),
        .pixel_out      (ctrl_pixel_out),
        .pixel_out_valid(ctrl_pixel_valid),
        .end_of_row     (end_of_row),
        .end_of_frame   (end_of_frame)
    );

    // 3. Kernel memory
    kernel_mem u_kernel_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .kernel_we      (kernel_we),
        .kernel_addr    (kernel_addr),
        .kernel_data    (kernel_data),
        .processing_en  (processing_en),
        .kernel_coeff   (kernel_coeffs)
    );

    // 4. Sliding window
    sliding_window u_sliding_window (
        .clk            (clk),
        .rst_n          (rst_n),
        .pixel_in       (ctrl_pixel_out),
        .pixel_valid    (ctrl_pixel_valid),
        .end_of_row     (end_of_row),
        .end_of_frame   (end_of_frame),
        .window         (window),
        .window_valid   (window_valid)
    );

    // 5. MAC array (instantiates K_DIM*K_DIM processing elements)
    MAC_array u_MAC_array (
        .clk            (clk),
        .rst_n          (rst_n),
        .processing_en  (processing_en),
        .window         (window),
        .window_valid   (window_valid),
        .kernel_coeffs  (kernel_coeffs),
        .conv_result    (conv_result),
        .conv_valid     (conv_valid)
    );

    // 6. ReLU
    relu u_relu (
        .conv_result    (conv_result),
        .conv_valid     (conv_valid),
        .relu_result    (relu_result),
        .relu_valid     (relu_valid)
    );

    // 7. Output formatter (descale + round + saturate)
    output_formatter u_output_formatter (
        .relu_result    (relu_result),
        .relu_valid     (relu_valid),
        .pixel_out      (fmt_pixel_out),
        .pixel_valid    (fmt_pixel_valid)
    );

    // 8. Output controller
    output_ctrl u_output_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .pixel_in       (fmt_pixel_out),
        .pixel_valid    (fmt_pixel_valid),
        .pixel_out      (pixel_out),
        .pixel_out_valid(pixel_out_valid),
        .done           (output_done)
    );
endmodule
