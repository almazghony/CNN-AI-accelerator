module output_formatter
    import conv_pkg::*;

(
    input  logic signed [ACC_W-1:0] relu_result,
    input  logic                    relu_valid,
    output logic [OUT_W-1:0]        pixel_out,
    output logic                    pixel_valid
);

    localparam int CALC_W = (ACC_W <= 32) ? 32 : ACC_W;

    localparam int MAX_OUT = 32'sd32767;
    localparam int MIN_OUT = -32'sd32768;

    logic signed [CALC_W-1:0] extended_result;
    logic signed [CALC_W-1:0] biased_result;
    logic signed [CALC_W-1:0] scaled_result;

    assign extended_result = relu_result;

    assign biased_result =
        (ROUND_EN && (SHIFT_AMT != 0)) ? extended_result + (CALC_W'(1) << (SHIFT_AMT - 1))
                                       : extended_result;

    assign scaled_result = biased_result >>> SHIFT_AMT;

    always_comb begin
        if (scaled_result > MAX_OUT)
            pixel_out = MAX_OUT[15:0];
        else if (scaled_result < MIN_OUT)
            pixel_out = MIN_OUT[15:0];
        else
            pixel_out = scaled_result[15:0];
    end

    assign pixel_valid = relu_valid;

endmodule
