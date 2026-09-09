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


    localparam int PTR_WIDTH = (IMG_MAX_W <= 1) ? 1 : $clog2(IMG_MAX_W);
    localparam int ROW_WIDTH = (K_DIM <= 1) ? 1 : $clog2(K_DIM);

    logic [PIX_WIDTH-1:0] lb[K_DIM-1][IMG_MAX_W];

    logic [PTR_WIDTH-1:0] ptr;


    logic [PIX_WIDTH-1:0] win[K_DIM][K_DIM];


    logic [ROW_WIDTH-1:0] rows_filled;
    logic [ROW_WIDTH-1:0] cols_filled;


    logic [PIX_WIDTH-1:0] lb_read[K_DIM-1];

    generate
        for (genvar i = 0; i < K_DIM-1; i++) begin : GEN_LB_READ
            assign lb_read[i] = lb[i][ptr];
        end
    endgenerate


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

            window_valid <= 1'b0;

            if (pixel_valid) begin


                if ((rows_filled >= K_DIM-1) &&
                    (cols_filled >= K_DIM-1)) begin

                    window_valid <= 1'b1;

                end


                for (int r = 0; r < K_DIM; r++) begin

                    for (int c = 0; c < K_DIM-1; c++) begin
                        win[r][c] <= win[r][c+1];
                    end

                    win[r][K_DIM-1] <= right_col_src[r];

                end

                lb[0][ptr] <= pixel_in;

                for (int i = 1; i < K_DIM-1; i++) begin
                    lb[i][ptr] <= lb_read[i-1];
                end

                if (end_of_row) begin

                    ptr <= '0;

                    if (rows_filled < K_DIM-1) begin
                        rows_filled <= rows_filled + 1'b1;
                    end

                    cols_filled <= '0;

                end

                else begin

                    ptr <= ptr + 1'b1;
                    if (cols_filled < K_DIM-1) begin
                        cols_filled <= cols_filled + 1'b1;
                    end

                end

            end

        end

    end

    generate

        for (genvar r = 0; r < K_DIM; r++) begin : GEN_WINDOW_R

            for (genvar c = 0; c < K_DIM; c++) begin : GEN_WINDOW_C

                assign window[r*K_DIM+c] = win[r][c];

            end

        end

    endgenerate

endmodule