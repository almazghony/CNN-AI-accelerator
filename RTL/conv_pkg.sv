
`ifndef CONV_PKG_SV
    `define CONV_PKG_SV

package conv_pkg;

    parameter int IMG_MAX_W = 32;
    parameter int IMG_MAX_H = 32;

    parameter int K_DIM     = 3;

    parameter int PIX_WIDTH = 8;
    parameter int WGT_WIDTH = 8;
    parameter int K_ADDR_W  = $clog2(K_DIM*K_DIM);
    parameter int OUT_W     = 16;

    parameter int WGT_FRAC  = 6;  // Q-format fractional bits for weights

    parameter int OUT_F_W   = IMG_MAX_W - K_DIM + 1;          // Max output feature-map width  (valid conv, stride=1)
    parameter int OUT_F_H   = IMG_MAX_H - K_DIM + 1;          // Max output feature-map height (valid conv, stride=1)
    parameter int PROD_W    = PIX_WIDTH + WGT_WIDTH + 1;
    parameter int PARTIAL_W = PROD_W + $clog2(K_DIM);
    parameter int ACC_W     = PARTIAL_W + $clog2(K_DIM);
    


endpackage

`endif
