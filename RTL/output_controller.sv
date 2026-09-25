module output_ctrl
    import conv_pkg::*;

(
    input  logic                clk,
    input  logic                rst_n,
    input  logic [OUT_W-1:0]    pixel_in,
    input  logic                pixel_valid,
    output logic [OUT_W-1:0]    pixel_out,
    output logic                pixel_out_valid,
    output logic                done
);

    logic [4:0] row_cnt;
    logic [4:0] col_cnt;

    // Output feature-map dimensions (valid convolution, stride = 1)

    logic        end_of_row;
    logic        last_pixel;

    assign end_of_row   = (col_cnt == OUT_F_W - 1);
    assign last_pixel   = (row_cnt == OUT_F_H - 1) && end_of_row;


    always_ff @(posedge clk) begin
        if(!rst_n) begin
            row_cnt <= 0;
            col_cnt <= 0;
            done <= 0;

        end
        else if(pixel_valid) begin
            done <= last_pixel;
            if(end_of_row) begin
                col_cnt <= 0;

                if(last_pixel)
                    row_cnt <= 0;
                else
                    row_cnt <= row_cnt + 1;
            end

            else
                col_cnt <= col_cnt + 1;
        end
        else begin
            done <= 1'b0;
        end
    end

    assign pixel_out_valid  = pixel_valid;
    assign pixel_out        = pixel_in;

endmodule