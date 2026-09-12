module top
    import conv_pkg::*;

(
    input  logic                            clk,
    input  logic                            rst_n,

    // Control
    input  logic                            start,
    output logic                            done,
    output logic                            processing_en,
    // Configuration (Directly to cfg.sv)
    // input  logic [7:0]                      cfg_img_width,
    // input  logic [7:0]                      cfg_img_height,

    // Kernel Loading
    input  logic                            kernel_we,
    input  logic [K_ADDR_W-1:0]             kernel_addr,
    input  logic [WGT_WIDTH-1:0]            kernel_data,

    // Input Image Stream (Directly to input_ctrl.sv)
    input  logic [PIX_WIDTH-1:0]            pixel_in,
    input  logic                            pixel_valid,

    // Output Feature Map Stream (Directly from output_ctrl.sv)
    output logic signed [OUT_W-1:0]         pixel_out,
    output logic                            pixel_out_valid
);

    // ---------------------------------------------------------------------
    // Internal Wires
    // ---------------------------------------------------------------------
    
    // Config outputs
    // logic [15:0]            img_width;
    // logic [15:0]            img_height;

    // Global control
    logic                   output_done;

    // Datapath streams
    logic [PIX_WIDTH-1:0]             ctrl_pixel_out;
    logic                   ctrl_pixel_valid;
    // logic [15:0]            row_idx;
    // logic [15:0]            col_idx;
    // logic                   image_done;

    logic [PIX_WIDTH-1:0]             window [K_DIM*K_DIM];
    logic                   window_valid;
    logic                   end_of_row;
    logic                   end_of_frame;

    logic signed [WGT_WIDTH-1:0]   kernel_coeffs [K_DIM*K_DIM];
    

    logic signed [PARTIAL_W-1:0]   partial_sum [K_DIM];
    logic                   partial_valid;

    logic signed [ACC_W-1:0]       conv_result;
    logic                   conv_valid;

    logic signed [ACC_W-1:0]       relu_result;
    logic                   relu_valid;

    logic [OUT_W-1:0]       fmt_pixel_out;
    logic                   fmt_pixel_valid;
    
    // logic [15:0]            out_f_w;
    // logic [15:0]            out_f_h;

    // ---------------------------------------------------------------------
    // Module Instantiations
    // ---------------------------------------------------------------------

    // 1. Configuration
    // cfg u_cfg (
    //     .clk            (clk),
    //     .rst_n          (rst_n),
    //     .processing_en           (processing_en),
    //     // .cfg_img_width  (cfg_img_width),
    //     // .cfg_img_height (cfg_img_height),
    //     .img_width      (img_width),
    //     .img_height     (img_height),
    //     .out_f_w        (out_f_w),
    //     .out_f_h        (out_f_h)
    // );

    // 2. Global Controller
    global_ctrl u_global_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .output_done    (output_done),
        .done           (done),
        .processing_en  (processing_en)
    );

    // 3. Input Controller (Replaces input_if + input_ctrl)
    input_ctrl u_input_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        // .img_width      (img_width),
        // .img_height     (img_height),
        .processing_en  (processing_en),
        .pixel_in       (pixel_in),
        .pixel_valid    (pixel_valid),
        .pixel_out      (ctrl_pixel_out),
        .pixel_out_valid(ctrl_pixel_valid),
        // .row_idx        (row_idx),
        // .col_idx        (col_idx),
        .end_of_row     (end_of_row),
        .end_of_frame   (end_of_frame)
    );

    // 4. Kernel Memory
    kernel_mem u_kernel_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .kernel_we      (kernel_we),
        .kernel_addr    (kernel_addr),
        .kernel_data    (kernel_data),
        .processing_en  (processing_en),
        .kernel_coeff   (kernel_coeffs)
    );

    // 5. Sliding Window
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

    // 6. MAC Array (Instantiates K_DIM*K_DIM processing_elements internally)
    MAC_array u_MAC_array (
        .clk            (clk),
        .rst_n          (rst_n), 
        .processing_en  (processing_en),
        .window         (window),
        .window_valid   (window_valid),
        .kernel_coeffs  (kernel_coeffs),
        .partial_sum    (partial_sum),
        .partial_valid  (partial_valid)
    );

    // 7. Accumulator
    accumulator u_accumulator (
        .partial_sum    (partial_sum),
        .partial_valid  (partial_valid),
        .conv_result    (conv_result),
        .conv_valid     (conv_valid)
    );

    // 8. ReLU
    relu u_relu (
        .conv_result    (conv_result),
        .conv_valid     (conv_valid),
        .relu_result    (relu_result),
        .relu_valid     (relu_valid)
    );

    // 9. Output Formatter
    output_formatter u_output_formatter (
        .relu_result    (relu_result),
        .relu_valid     (relu_valid),
        .pixel_out      (fmt_pixel_out),
        .pixel_valid    (fmt_pixel_valid)
    );

    // 10. Output Controller
    output_ctrl u_output_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        // .out_f_w        (out_f_w),
        // .out_f_h        (out_f_h),
        .pixel_in       (fmt_pixel_out),
        .pixel_valid    (fmt_pixel_valid),
        .pixel_out      (pixel_out),
        .pixel_out_valid(pixel_out_valid),
        .done           (output_done)
    );

endmodule