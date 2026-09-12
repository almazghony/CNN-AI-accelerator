module fpga_test_top
    import conv_pkg::*;

(
    input  logic clk,
    input  logic btn_reset,
    input  logic btn_start,

    output logic led_busy,
    output logic led_done
);

    // =========================================================
    // Convert active-high physical reset button
    // to active-low accelerator reset
    // =========================================================
    logic rst_n;

    assign rst_n = ~btn_reset;


    // =========================================================
    // Signals to/from accelerator
    // =========================================================

    logic kernel_we;
    logic [K_ADDR_W-1:0] kernel_addr;
    logic [WGT_WIDTH-1:0] kernel_data;

    logic [PIX_WIDTH-1:0] pixel_in;
    logic pixel_valid;

    logic signed [OUT_W-1:0] pixel_out;
    logic pixel_out_valid;

    logic processing_en;
    logic done;


    // =========================================================
    // Kernel loader
    //
    // Identity 3x3 kernel:
    //
    // 1 0 0
    // 0 1 0
    // 0 0 1
    //
    // Q1.6:
    // 1.0 = 64
    // =========================================================

    logic [K_ADDR_W-1:0] kernel_count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            kernel_count <= '0;
        end
        else if (!processing_en) begin
            if (kernel_count == K_DIM*K_DIM-1)
                kernel_count <= '0;
            else
                kernel_count <= kernel_count + 1'b1;
        end
    end

    assign kernel_we   = !processing_en;
    assign kernel_addr = kernel_count;

    always_comb begin
        case (kernel_count)

            4'd0: kernel_data = 8'd64;
            4'd1: kernel_data = 8'd0;
            4'd2: kernel_data = 8'd0;

            4'd3: kernel_data = 8'd0;
            4'd4: kernel_data = 8'd64;
            4'd5: kernel_data = 8'd0;

            4'd6: kernel_data = 8'd0;
            4'd7: kernel_data = 8'd0;
            4'd8: kernel_data = 8'd64;

            default: kernel_data = 8'd0;

        endcase
    end


    // =========================================================
    // Test image
    //
    // 32 x 32 = 1024 pixels
    // Every pixel = 1
    // =========================================================

    logic [10:0] pixel_count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pixel_count <= '0;
        end
        else if (!processing_en) begin
            pixel_count <= '0;
        end
        else if (pixel_count < 11'd1024) begin
            pixel_count <= pixel_count + 1'b1;
        end
    end

    assign pixel_in = 8'd1;

    assign pixel_valid =
        processing_en && (pixel_count < 11'd1024);


    // =========================================================
    // Accelerator
    // =========================================================

    top u_accelerator (
        .clk             (clk),
        .rst_n           (rst_n),

        .start           (btn_start),
        .done            (done),
        .processing_en            (processing_en),

        .kernel_we       (kernel_we),
        .kernel_addr     (kernel_addr),
        .kernel_data     (kernel_data),

        .pixel_in        (pixel_in),
        .pixel_valid     (pixel_valid),

        .pixel_out       (pixel_out),
        .pixel_out_valid (pixel_out_valid)
    );


    // =========================================================
    // LEDs
    // =========================================================

    assign led_busy = processing_en;
    assign led_done = done;

endmodule