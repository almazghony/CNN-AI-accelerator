module sliding_window
    import conv_pkg::*;

(
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic [PIX_WIDTH-1:0]    pixel_in,
    input  logic                    pixel_valid,

    input  logic                    end_of_row,
    input  logic                    end_of_frame,

    output logic [PIX_WIDTH-1:0]    window[K_DIM*K_DIM],
    output logic                    window_valid
);

    // ------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------

    localparam int PTR_WIDTH = (IMG_MAX_W <= 1) ? 1 : $clog2(IMG_MAX_W);
    localparam int ROW_WIDTH = (K_DIM <= 1) ? 1 : $clog2(K_DIM);

    // ------------------------------------------------------------
    // Line buffers
    //
    // lb[0] = previous row
    // lb[1] = two rows previous
    // ...
    //
    // Example for K_DIM = 3:
    //
    // lb[0][col] = pixel from row-1
    // lb[1][col] = pixel from row-2
    // ------------------------------------------------------------

    logic [PIX_WIDTH-1:0] lb[K_DIM-1][IMG_MAX_W];

    logic [PTR_WIDTH-1:0] ptr;

    // ------------------------------------------------------------
    // Internal window
    //
    // win[row][column]
    // ------------------------------------------------------------

    logic [PIX_WIDTH-1:0] win[K_DIM][K_DIM];

    // ------------------------------------------------------------
    // Number of rows/columns currently available
    //
    // rows_filled:
    //   0 -> no previous row available
    //   1 -> one previous row available
    //   2 -> two previous rows available
    //
    // cols_filled:
    //   number of pixels currently accumulated in current row,
    //   limited to K_DIM.
    // ------------------------------------------------------------

    logic [ROW_WIDTH-1:0] rows_filled;
    logic [ROW_WIDTH-1:0] cols_filled;

    // ------------------------------------------------------------
    // Read current column from line buffers
    // ------------------------------------------------------------

    logic [PIX_WIDTH-1:0] lb_read[K_DIM-1];

    generate
        for (genvar i = 0; i < K_DIM-1; i++) begin : GEN_LB_READ
            assign lb_read[i] = lb[i][ptr];
        end
    endgenerate

    // ------------------------------------------------------------
    // Right-most column of the window
    //
    // For K_DIM = 3:
    //
    // right_col_src[0] = row-2
    // right_col_src[1] = row-1
    // right_col_src[2] = current pixel
    // ------------------------------------------------------------

    logic [PIX_WIDTH-1:0] right_col_src[K_DIM];

    generate
        for (genvar r = 0; r < K_DIM; r++) begin : GEN_RIGHT_COLUMN

            if (r == K_DIM-1) begin

                assign right_col_src[r] = pixel_in;

            end
            else begin

                assign right_col_src[r] =
                    lb_read[K_DIM-2-r];

            end

        end
    endgenerate

    // ------------------------------------------------------------
    // Sequential logic
    // ------------------------------------------------------------

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            ptr          <= '0;
            rows_filled  <= '0;
            cols_filled  <= '0;
            window_valid <= 1'b0;

            for (int r = 0; r < K_DIM; r++) begin
                for (int c = 0; c < K_DIM; c++) begin
                    win[r][c] <= '0;
                end
            end

            for (int r = 0; r < K_DIM-1; r++) begin
                for (int c = 0; c < IMG_MAX_W; c++) begin
                    lb[r][c] <= '0;
                end
            end

        end

        else begin

            // Default: no valid window unless a valid pixel
            // completes one in this cycle.
            window_valid <= 1'b0;

            if (pixel_valid) begin

                // ------------------------------------------------
                // Determine whether CURRENT pixel completes
                // a K_DIM x K_DIM window.
                //
                // rows_filled represents previous complete rows.
                // cols_filled represents pixels already present
                // in the current row BEFORE pixel_in.
                //
                // Therefore:
                //
                // rows_filled >= K_DIM-1
                // AND
                // cols_filled >= K_DIM-1
                //
                // means this current pixel completes the window.
                // ------------------------------------------------

                if ((rows_filled >= K_DIM-1) &&
                    (cols_filled >= K_DIM-1)) begin

                    window_valid <= 1'b1;

                end

                // ------------------------------------------------
                // Shift window left
                // ------------------------------------------------

                for (int r = 0; r < K_DIM; r++) begin

                    for (int c = 0; c < K_DIM-1; c++) begin
                        win[r][c] <= win[r][c+1];
                    end

                    win[r][K_DIM-1] <= right_col_src[r];

                end

                // ------------------------------------------------
                // Update line buffers
                // ------------------------------------------------

                lb[0][ptr] <= pixel_in;

                for (int i = 1; i < K_DIM-1; i++) begin
                    lb[i][ptr] <= lb_read[i-1];
                end

                // ------------------------------------------------
                // Column tracking
                // ------------------------------------------------

                if (end_of_row) begin

                    ptr <= '0;

                    // A complete row has just arrived.
                    //
                    // Saturate at K_DIM-1 because we only care
                    // whether enough previous rows exist.
                    if (rows_filled < K_DIM-1) begin
                        rows_filled <= rows_filled + 1'b1;
                    end

                    cols_filled <= '0;

                end

                else begin

                    ptr <= ptr + 1'b1;

                    // Saturate at K_DIM-1.
                    //
                    // We don't need the exact column count after
                    // the window becomes possible.
                    if (cols_filled < K_DIM-1) begin
                        cols_filled <= cols_filled + 1'b1;
                    end

                end

            end

        end

    end

    // ------------------------------------------------------------
    // Flatten 2-D window
    //
    // window:
    //
    // [0] [1] [2]
    // [3] [4] [5]
    // [6] [7] [8]
    //
    // ------------------------------------------------------------

    generate

        for (genvar r = 0; r < K_DIM; r++) begin : GEN_WINDOW_R

            for (genvar c = 0; c < K_DIM; c++) begin : GEN_WINDOW_C

                assign window[r*K_DIM+c] = win[r][c];

            end

        end

    endgenerate

endmodule