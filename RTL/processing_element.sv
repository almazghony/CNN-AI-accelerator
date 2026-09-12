// Fixed-point multiply.
//   pixel : Q(PIX_WIDTH).PIX_FRAC unsigned  (Q8.0 -> plain 8-bit integer, 0-255)
//   coeff : Q(WGT_WIDTH-1-WGT_FRAC).WGT_FRAC signed (Q1.6 -> range [-2.0, +1.984375])
//   product: Q(PROD_W-PROD_FRAC-1).PROD_FRAC signed, where PROD_FRAC = PIX_FRAC+WGT_FRAC.
//            No shifting is done here: the fractional point simply moves
//            right by WGT_FRAC bits relative to the integer product bits.
//            That rescale is deferred to output_formatter, after
//            accumulation, so only one shifter/rounder/saturator is
//            needed for the whole datapath.
module processing_element
    import conv_pkg::*;
(
        input   logic unsigned [PIX_WIDTH-1:0]  pixel,
        input   logic signed [WGT_WIDTH-1:0]    coeff,   
        output  logic signed [PROD_W-1 : 0]     product
);
    assign product = $signed({1'b0, pixel}) * coeff;
endmodule
