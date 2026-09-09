module processing_element
    import conv_pkg::*;
(
        input   logic unsigned [PIX_WIDTH-1:0]  pixel,
        input   logic signed [WGT_WIDTH-1:0]    coeff,   
        output  logic signed [PROD_W-1 : 0]     product
);

    assign product = $signed({1'b0, pixel}) * coeff;
endmodule
