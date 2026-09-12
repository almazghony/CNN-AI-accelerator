package shared_pkg;

    typedef enum {
        TX_RESET, 
        TX_PROG_KERNEL, 
        TX_START, 
        TX_PIXEL, 
        TX_IDLE_GAP
    } conv_txn_e;

        parameter int IMG_MAX_W = conv_pkg::IMG_MAX_W;
        parameter int IMG_MAX_H = conv_pkg::IMG_MAX_H;
        parameter int K_DIM     = conv_pkg::K_DIM;

        parameter int PIX_WIDTH = conv_pkg::PIX_WIDTH;
        parameter int WGT_WIDTH = conv_pkg::WGT_WIDTH;
        parameter int K_ADDR_W  = conv_pkg::K_ADDR_W;
        parameter int OUT_W     = conv_pkg::OUT_W;

        parameter int PIX_FRAC  = conv_pkg::PIX_FRAC;
        parameter int WGT_FRAC  = conv_pkg::WGT_FRAC;
        parameter int PROD_FRAC = conv_pkg::PROD_FRAC;

        parameter int OUT_F_W   = conv_pkg::OUT_F_W;
        parameter int OUT_F_H   = conv_pkg::OUT_F_H;
        parameter int PROD_W    = conv_pkg::PROD_W;
        parameter int PARTIAL_W = conv_pkg::PARTIAL_W;
        parameter int ACC_W     = conv_pkg::ACC_W;

        parameter bit RELU_EN   = conv_pkg::RELU_EN;
        parameter bit ROUND_EN  = conv_pkg::ROUND_EN;
        parameter int SHIFT_AMT = conv_pkg::SHIFT_AMT;

endpackage