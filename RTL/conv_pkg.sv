`ifndef CONV_PKG
    `define CONV_PKG_

    package conv_pkg;

        parameter int IMG_MAX_W = 32;
        parameter int IMG_MAX_H = 32;

        parameter int K_DIM     = 3;

        parameter int PIX_WIDTH = 8;
        parameter int WGT_WIDTH = 8;
        parameter int K_ADDR_W  = $clog2(K_DIM*K_DIM);
        parameter int OUT_W     = 16;

        parameter int PIX_FRAC  = 0;
        parameter int WGT_FRAC  = 6;
        parameter int PROD_FRAC = PIX_FRAC + WGT_FRAC;

        parameter int OUT_F_W   = IMG_MAX_W - K_DIM + 1;
        parameter int OUT_F_H   = IMG_MAX_H - K_DIM + 1;

        parameter int PROD_W    = PIX_WIDTH + WGT_WIDTH;
        parameter int PARTIAL_W = PROD_W + $clog2(K_DIM);
        parameter int ACC_W     = PARTIAL_W + $clog2(K_DIM);
        
        parameter bit RELU_EN   = 1; 
        parameter bit ROUND_EN  = 1; 
        parameter int SHIFT_AMT = PROD_FRAC;

    endpackage

`endif