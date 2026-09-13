`ifndef CONV_PKG
    `define CONV_PKG_

    package conv_pkg;

        parameter int IMG_MAX_W = 32;
        parameter int IMG_MAX_H = 32;

        parameter int K_DIM     = 3;


        // -------------------------------------------------------------------
        // Fixed-point (Q-format) precision definitions
        // -------------------------------------------------------------------
        // Input pixel:   Q(PIX_WIDTH).PIX_FRAC, UNSIGNED
        //   -> Q8.0 unsigned. Raw 8-bit image/activation intensities (0-255)
        //      are natively integer; no fractional bits are needed since the
        //      sensor/upstream source never supplies sub-integer precision.
        // Kernel weight: Q(WGT_WIDTH-1-WGT_FRAC).WGT_FRAC, SIGNED (2's complement)
        //   -> Q1.6 signed (1 sign bit + 1 integer bit + 6 fractional bits).
        //      Range = [-2.0, +1.984375], resolution = 1/64 = 0.015625.
        //      Chosen because trained convolution kernel coefficients are
        //      typically normalized to roughly [-1, +1]; Q1.6 keeps that
        //      range representable with one bit of headroom for outliers
        //      while maximizing fractional resolution within an 8-bit budget.
        // Product/partial-sum/accumulator: fractional bits = PIX_FRAC+WGT_FRAC
        //      Multiplication adds fractional-bit counts; addition (the
        //      MAC tree) does not change the fractional-bit count. So every
        //      stage from the multiplier through the final adder stays in
        //      Q(x).PROD_FRAC format automatically - no extra shifting is
        //      needed until the very end.
        // Output: SHIFT_AMT = PROD_FRAC descales the Q(x).PROD_FRAC
        //      accumulator result back to an integer-valued (Q16.0) domain
        //      before rounding and saturating to the 16-bit signed output.
        // -------------------------------------------------------------------

        parameter int PIX_WIDTH = 8;
        parameter int WGT_WIDTH = 8;
        parameter int K_ADDR_W  = $clog2(K_DIM*K_DIM);
        parameter int OUT_W     = 16;

        parameter int PIX_FRAC  = 0;
        parameter int WGT_FRAC  = 6;
        parameter int PROD_FRAC = PIX_FRAC + WGT_FRAC;

        parameter int OUT_F_W   = IMG_MAX_W - K_DIM + 1;
        parameter int OUT_F_H   = IMG_MAX_H - K_DIM + 1;
        parameter int PROD_W    = PIX_WIDTH + WGT_WIDTH + 1;
        parameter int PARTIAL_W = PROD_W + $clog2(K_DIM);
        parameter int ACC_W     = PARTIAL_W + $clog2(K_DIM);
        
        parameter bit RELU_EN   = 1; 
        parameter bit ROUND_EN  = 1; 
        parameter int SHIFT_AMT = PROD_FRAC;  // descale Q(x).PROD_FRAC accumulator down to Q16.0 output

    endpackage

`endif