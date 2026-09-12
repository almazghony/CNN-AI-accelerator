module accumulator
    import conv_pkg::*;

(   input   wire  signed [PARTIAL_W-1:0]    partial_sum [K_DIM],
    input   logic                           partial_valid,
    output  logic signed [ACC_W-1:0]        conv_result,
    output  logic                           conv_valid
);

    
    logic signed [ACC_W-1:0] sum;
    always_comb begin
        sum = 0;
        //adder tree
        for(int i = 0; i<K_DIM; i++)
            sum = sum + partial_sum[i];
        conv_result = sum;
    end

    assign conv_valid = partial_valid;
endmodule