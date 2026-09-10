// cfg.sv — runtime configuration register bank
module cfg
    import conv_pkg::*;
(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            busy,
    // input  logic [15:0]     cfg_img_width,
    // input  logic [15:0]     cfg_img_height,
    output logic [7:0]      img_width, 
    output logic [7:0]      img_height,
    output logic [15:0]     out_f_w,
    output logic [15:0]     out_f_h   
);


    always_ff @(posedge clk) begin
        if (!rst_n) begin //rst==0
            img_width  <= 16'd32;  
            img_height <= 16'd32;
            out_f_w    <= 0;   
            out_f_h    <= 0;   
        end
        else if(!busy) begin //busy==0
            img_width  <= cfg_img_width;
            img_height <= cfg_img_height;
            out_f_w    <= cfg_img_width  - (K_DIM - 1);
            out_f_h    <= cfg_img_height - (K_DIM - 1);
        end
        // else (busy = 1, PROCESSING) → no branch taken → registers HOLD = read-only
    end

endmodule