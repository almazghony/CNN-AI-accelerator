module kernel_mem
    import conv_pkg::*;

(
    input   logic                         clk,
    input   logic                         rst_n,
    input   logic                         kernel_we,
    input   logic [K_ADDR_W-1:0]          kernel_addr,
    input   logic [WGT_WIDTH-1:0]         kernel_data,
    input   logic                         processing_en,
    output  logic signed [WGT_WIDTH-1:0]  kernel_coeff[K_DIM*K_DIM]
);

    logic signed [WGT_WIDTH-1:0] kernel_mem [0:K_DIM*K_DIM-1];


    always_ff @(posedge clk)
        //The kernel must always be programmed by software/testbench before START
        if(!processing_en && kernel_we)
                kernel_mem[kernel_addr] <= kernel_data;

    
    generate
        for(genvar i = 0; i < K_DIM*K_DIM; i++)
                assign kernel_coeff[i] = kernel_mem[i];
    endgenerate
endmodule