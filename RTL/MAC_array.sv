module MAC_array
import conv_pkg::*;
(
    input  logic                             clk,
    input  logic                             rst_n,
    input  logic                             processing_en,
    input  wire          [PIX_WIDTH-1:0]     window[K_DIM*K_DIM],
    input  logic                             window_valid,
    input  wire   signed [WGT_WIDTH-1:0]     kernel_coeffs[K_DIM*K_DIM],
    output logic  signed [ACC_W-1:0]         conv_result,
    output logic                             conv_valid
);

    // Local kernel coefficient registers
    logic signed [WGT_WIDTH-1:0] kernel_coeff_local [K_DIM*K_DIM];
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            kernel_coeff_local <= '{default: 0};
        end
        else if (!processing_en) begin
            kernel_coeff_local <= kernel_coeffs;
        end
    end

    parameter IP_LATENCY = 1;

    logic signed [PROD_W-1:0] product [K_DIM*K_DIM];
    logic [IP_LATENCY-1:0]    ip_valid_pipe;

    // Pipeline stage 1 - register the products
    logic signed [PROD_W-1:0] product_reg [K_DIM*K_DIM];
    logic                     window_valid_reg;

    // Pipeline stage 2 - register the row partial sums
    logic signed [ACC_W-1:0]  row_sum_reg [K_DIM];
    logic                     conv_valid_reg;

    generate
        for(genvar i=0; i < K_DIM*K_DIM; i++) begin : GEN_PE
            mult_gen_0 u_PE (
                .CLK(clk),
                .A  (window[i]),
                .B  (kernel_coeff_local[i]),
                .P  (product[i])
            );
        end
    endgenerate

    // 2. Register the products (PIPELINE STAGE 1) + align valid
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            product_reg      <= '{default: 0};
            ip_valid_pipe    <= '0;
            window_valid_reg <= 1'b0;
        end
        else begin
            product_reg <= product;
            for (int k = IP_LATENCY-1; k > 0; k--)
                ip_valid_pipe[k] <= ip_valid_pipe[k-1];
            ip_valid_pipe[0] <= window_valid;
            window_valid_reg <= ip_valid_pipe[IP_LATENCY-1];
        end
    end

    // 3. Accumulate (Row-wise partial sums) - COMBINATIONAL
    logic signed [ACC_W-1:0] row_sum [K_DIM];
    always_comb begin
        for(int i=0; i<K_DIM; i++) begin
            row_sum[i] = '0;
            for(int j=0; j<K_DIM; j++) begin
                row_sum[i] = row_sum[i] + product_reg[i*K_DIM + j];
            end
        end
    end

    // 4. Register the partial sums (PIPELINE STAGE 2) + final accumulation
    logic signed [ACC_W-1:0] sum_comb;

    always_comb begin
        sum_comb = '0;
        for(int i=0; i<K_DIM; i++)
            sum_comb = sum_comb + row_sum_reg[i];
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            row_sum_reg     <= '{default: 0};
            conv_valid_reg  <= 1'b0;
            conv_result     <= '0;
            conv_valid      <= 1'b0;
        end
        else begin
            row_sum_reg     <= row_sum;
            conv_valid_reg  <= window_valid_reg;
            conv_result     <= sum_comb;
            conv_valid      <= conv_valid_reg;
        end
    end

endmodule