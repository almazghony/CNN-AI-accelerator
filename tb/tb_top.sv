
module tb_top;
    import conv_pkg::*;
    parameter TB_IMG_H = 32;
    parameter TB_IMG_W = 32;
    parameter MID = (K_DIM-1)/2;
    logic clk = 0;
    logic rst_n;
    logic                                       start, done, busy;
    // logic           [15:0]                      cfg_img_width, cfg_img_height;
    logic                                       kernel_we;
    logic           [K_ADDR_W-1:0]              kernel_addr;
    logic           [WGT_WIDTH-1:0]             kernel_data;
    logic unsigned  [PIX_WIDTH-1:0]             pixel_in;
    logic                                       pixel_valid;
    logic           [OUT_W-1:0]                 pixel_out;
    logic                                       pixel_out_valid;
    // logic                                    pixel_out_last;
    // logic                                    overflow_out;

    logic [15:0] out_f_w;
    logic [15:0] out_f_h;
    
    assign out_f_w        = IMG_MAX_W  - (K_DIM - 1);
    assign out_f_h        = IMG_MAX_H  - (K_DIM - 1);

    top dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .start           (start),
        .done            (done),
        .busy            (busy),
        // .cfg_img_width   (cfg_img_width),
        // .cfg_img_height  (cfg_img_height),
        .kernel_we       (kernel_we),
        .kernel_addr     (kernel_addr),
        .kernel_data     (kernel_data),
        .pixel_in        (pixel_in),
        .pixel_valid     (pixel_valid),
        .pixel_out       (pixel_out),
        .pixel_out_valid (pixel_out_valid)
        // .pixel_out_last  (pixel_out_last),
        // .overflow_out    (overflow_out)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    // Ramp test image / expected output storage
    logic [PIX_WIDTH-1:0] image[TB_IMG_H][TB_IMG_W];
    logic [OUT_W-1:0] result[OUT_F_H][OUT_F_W];

    int errors;
    int out_r, out_c;

    task program_identity_kernel();
        for (int r = 0; r < K_DIM; r++) begin
            for (int c = 0; c < K_DIM; c++) begin
                @(negedge clk);
                kernel_we   <= 1'b1;
                kernel_addr <= r*K_DIM + c;
                kernel_data <= (r == MID && c == MID) ? 1 : 0;
            end
        end
        @(negedge clk);
        kernel_we <= 1'b0;
    endtask

    task gen_ramp_image();
        for (int r = 0; r < IMG_MAX_H; r++)
            for (int c = 0; c < IMG_MAX_W; c++)
                image[r][c] = (r*IMG_MAX_W + c) % (1 << PIX_WIDTH);
    endtask

    // Drives one pixel per clock cycle, back-to-back
    task stream_image();
        for (int r = 0; r < IMG_MAX_H; r++) begin
            for (int c = 0; c < IMG_MAX_W; c++) begin
                @(negedge clk);
                pixel_in    <= image[r][c];
                pixel_valid <= 1'b1;
            end
        end
        @(negedge clk);
        pixel_valid <= 1'b0;
    endtask

    // Collect output samples into result[][] as they stream out
    always_ff @(negedge clk) begin
        if (!rst_n) begin
            out_r <= 0;
            out_c <= 0;
        end else if (pixel_out_valid) begin
            result[out_r][out_c] <= pixel_out;
            if (out_c == out_f_w-1) begin
                out_c <= 0;
                out_r <= out_r + 1;
            end
            else
                out_c <= out_c + 1;
        end
    end

    initial begin
        rst_n  = 0;

        @(negedge clk);

        rst_n = 1;
        start          = 0;
        // cfg_img_width  = 4;
        // cfg_img_height = 4;
        kernel_we      = 0;
        kernel_addr    = 0;
        kernel_data    = 0;
        pixel_in       = 0;
        pixel_valid    = 0;
        errors         = 0;
        
        @(negedge clk);
        
        gen_ramp_image();
        program_identity_kernel();

        start <= 1'b1;
        @(negedge clk);
        start <= 1'b0;

        stream_image();

        // Wait for the last output sample (with a generous timeout).
        // NOTE: pixel_out_valid/pixel_out_last settle via NBA on the clock
        // edge they're asserted on; the result[][] capture block (also
        // clocked) only samples that settled value on the *next* edge. So
        // after 'wait' unblocks we hold for a couple of extra clocks (+ a
        // small delta delay) to be sure that final NBA-scheduled write has
        // actually committed before we read result[][] below.
        fork
            begin : wait_done
                wait (done);
                repeat (2) @(negedge clk);
            end
            begin : timeout
                repeat (2000) @(negedge clk);
                $display("TIMEOUT: frame never completed (pixel_out_last never asserted)");
                errors++;
            end
        join_any
        disable fork;

        

        // Check identity-kernel passthrough: out[r][c] == image[r+MID][c+MID]
        // for (int r = 0; r < out_f_h; r++) begin
        //     for (int c = 0; c < out_f_w; c++) begin
        //         automatic logic  [OUT_W-1:0] expected = image[r+MID][c+MID];
        //         if (result[r][c] !== expected) begin
        //             $display("[time: %0t] MISMATCH [%0d][%0d]: expected=%0d got=%0d", $time(), r, c, expected, result[r][c]);
        //             errors++;
        //         end
        //     end
        // end

        // if (errors == 0)
        //     $display("PASS: conv_top identity-kernel smoke test matched %0d output pixels.", out_f_h*out_f_w);
        // else
        //     $display("FAIL: %0d mismatch(es).", errors);
        $stop;
        
    end

endmodule