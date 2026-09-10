module input_ctrl
    import conv_pkg::*;

(
    input  logic                    clk,
    input  logic                    rst_n,
    // input  logic [15:0]             img_width,
    // input  logic [15:0]             img_height,
    input  logic                    processing_en,

    
    input  logic [PIX_WIDTH-1:0]    pixel_in,
    input  logic                    pixel_valid,

    output logic [PIX_WIDTH-1:0]    pixel_out,
    output logic                    pixel_out_valid,
    // output logic [15:0]          row_idx,
    // output logic [15:0]          col_idx,
    output logic                    end_of_row,
    output logic                    end_of_frame
);
    logic [15:0] row_cnt;
    logic [15:0] col_cnt;

    wire   accept           = processing_en && pixel_valid;
    assign pixel_out        = pixel_in;
    // assign pixel_out_valid  = accept;
    // assign row_idx       = row_cnt;
    // assign col_idx       = col_cnt;


    always_ff @(posedge clk) begin
        if(!rst_n) begin
            row_cnt <= 0;
            col_cnt <= 0;
        end
        else if (!processing_en)begin
            row_cnt <= 0;
            col_cnt <= 0;
        end
        else if(accept) begin
            if(end_of_row) begin
                col_cnt     <= 0;
                
                if(end_of_frame) begin
                    row_cnt <= 0;
                end
                else
                    row_cnt <= row_cnt + 1;
            end
            else
                col_cnt <= col_cnt + 1;
        end
    end
    assign end_of_row = (col_cnt == IMG_MAX_W-1);
    assign end_of_frame = (row_cnt == IMG_MAX_H-1) && end_of_row;
    assign pixel_out_valid = processing_en && pixel_valid && rst_n; 
endmodule