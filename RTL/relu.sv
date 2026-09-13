module relu
    import conv_pkg::*;

(
    input   logic signed [ACC_W-1:0]    conv_result,
    input   logic                       conv_valid,
    output  logic signed [ACC_W-1:0]    relu_result,
    output  logic                       relu_valid
);

    assign relu_result = (RELU_EN && conv_result[ACC_W-1]) ? '0 : conv_result;
    assign relu_valid  = conv_valid;
endmodule