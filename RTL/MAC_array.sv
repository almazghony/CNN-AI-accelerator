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
    // Pipeline Stage 1: Multiplication outputs
    logic signed [PROD_W-1:0] product_reg [K_DIM*K_DIM];
    logic                     window_valid_reg;
    
    // Pipeline Stage 2: Accumulation outputs  
    logic signed [PARTIAL_W-1:0] row_sum_reg [K_DIM];
    logic                        partial_valid_reg;

    // 1. Multiply (Processing Elements) - COMBINATIONAL
    logic signed [PROD_W-1:0] product [K_DIM*K_DIM];
    generate
        for(genvar i=0; i < K_DIM*K_DIM; i++) begin : GEN_PE
            processing_element u_PE (
                .pixel  (window[i]),
                .coeff  (kernel_coeffs[i]),   
                .product(product[i])
            );
        end
    endgenerate

    // 2. Register the products (PIPELINE STAGE 1)
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            product_reg      <= '{default: 0};
            window_valid_reg <= 1'b0;
        end
        else begin
            product_reg      <= product;
            window_valid_reg <= window_valid;
        end
    end

    // 3. Accumulate (Row-wise partial sums) - COMBINATIONAL
    logic signed [PARTIAL_W-1:0] row_sum [K_DIM];
    always_comb begin
        for(int i=0; i<K_DIM; i++) begin
            row_sum[i] = '0;
            for(int j=0; j<K_DIM; j++) begin
                row_sum[i] = row_sum[i] + product_reg[i*K_DIM + j];
            end
        end
    end

    // 4. Register the partial sums (PIPELINE STAGE 2)
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            partial_sum     <= '{default: 0};
            partial_valid   <= 1'b0;
        end
        else begin
            row_sum_reg     <= row_sum;
            partial_valid_reg <= window_valid_reg;
            partial_sum     <= row_sum_reg;
            partial_valid   <= partial_valid_reg;
        end
    end

endmodule