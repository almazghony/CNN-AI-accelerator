//Generates one valid N×N convolution window from the incoming pixel stream.
//combining Line Buffers and a Window Generator into a single module.
//Maximizes data reuse and minimizes memory bandwidth.

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

    localparam PTR_WIDTH = $clog2(IMG_MAX_W);
    localparam CTR_WIDTH = $clog2(K_DIM+1);


    logic [PIX_WIDTH-1:0]   lb [K_DIM-1][IMG_MAX_W];
    logic [PTR_WIDTH-1:0]   ptr; //points to the current column of the lb's
    
    logic [PIX_WIDTH-1:0]   win [K_DIM][K_DIM];

    logic [CTR_WIDTH-1:0]   rows_filled, cols_filled;

    // Right column sources: bottom row = new pixel, upper rows = line buffers
    wire [PIX_WIDTH-1:0]    right_col_src [K_DIM];

    wire [PIX_WIDTH-1:0]    lb_read [K_DIM-1];   //the column to fill in the window from the lb

    generate 
        for(genvar i = 0; i < K_DIM-1; i++) begin
            assign lb_read[i] = lb[i][ptr];
        end
    endgenerate



    generate
        for(genvar r=0; r < K_DIM; r++)
           assign right_col_src[r] = (r == K_DIM-1)? pixel_in : lb_read[K_DIM-2-r];
    endgenerate

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            ptr             <= 0;
            rows_filled     <= 0;
            cols_filled     <= 0;
            window_valid    <= 0;  
        end

        else if(pixel_valid) begin
              window_valid <= (rows_filled == K_DIM - 1) && (cols_filled == K_DIM);
            
            for(int r = 0; r < K_DIM; r++) begin
                for(int c = 0; c < K_DIM-1; c++) 
                    win[r][c] <= win[r][c+1];
                win[r][K_DIM-1] <= right_col_src[r];
            end
            
            lb[0][ptr] <= pixel_in;
            for(int i = 1; i < K_DIM-1; i++)
                lb[i][ptr] <= lb_read[i-1];


            ptr <= (end_of_row) ? 0 : ptr + 1;

            if(cols_filled == K_DIM) begin
                if(rows_filled < K_DIM - 1) begin
                    rows_filled <= rows_filled + 1;
                    cols_filled <= 0;
                end
                else if(end_of_row && !end_of_frame)
                        cols_filled <= 0;
            end
            else 
                cols_filled <= cols_filled + 1;
        end
    end

    for(genvar r = 0; r < K_DIM; r++) begin
        for(genvar c = 0; c < K_DIM; c++) 
            assign window[r*K_DIM + c] = win[r][c];
    end
endmodule