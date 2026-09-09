module MAC_array
    import conv_pkg::*;

(
        input  logic                             clk,           
        input  logic                             rst_n,
        input  wire         [PIX_WIDTH-1:0]      window[K_DIM*K_DIM],
        input  logic                             window_valid,
        input  wire   signed [WGT_WIDTH-1:0]     kernel_coeffs[K_DIM*K_DIM],
        output logic  signed [PARTIAL_W - 1 : 0] partial_sum[K_DIM],
        output logic                             partial_valid
);

    logic  signed [PARTIAL_W-1 : 0]  row_sum [K_DIM];
    logic  signed [PROD_W-1 : 0]     product [K_DIM*K_DIM];

    // 1. Multiply (Processing Elements)
    generate
        for(genvar i=0; i < K_DIM*K_DIM; i++) begin
            processing_element PE (
                    .pixel(window[i]),
                    .coeff(kernel_coeffs[i]),   
                    .product(product[i])
                );
        end
    endgenerate

    // 2. Accumulate (Row-wise partial sums)
    always_comb begin
        for(int i=0; i<K_DIM; i++) begin
            row_sum[i] = 0;
            for(int j=0; j<K_DIM; j++)
                row_sum[i] = row_sum[i] + product[i*K_DIM + j];
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n)
            partial_valid <= 0;
        
        else begin
            partial_sum     <= row_sum;
            partial_valid   <= window_valid;
        end
    end

endmodule