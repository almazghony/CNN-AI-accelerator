module output_formatter
    import conv_pkg::*;

(
    input  logic signed [ACC_W-1:0] relu_result,
    input  logic                    relu_valid,
    output logic [OUT_W-1:0]        pixel_out,
    output logic                    pixel_valid
);

        localparam int CALC_W = (ACC_W <= 32) ? 32 : ACC_W;

        //signed 16-bit range
        localparam int MAX_OUT = 32'sd32767;
        localparam int MIN_OUT = -32'sd32768;

        logic signed [CALC_W-1:0] extended_result;
        logic signed [CALC_W-1:0] biased_result;
        logic signed [CALC_W-1:0] scaled_result;


        // Sign-extend input
        assign extended_result = relu_result;

        // Optional rounding (bias = half the divisor)
            assign biased_result = 
                (ROUND_EN && (SHIFT_AMT != 0))? extended_result + (CALC_W'(1) << (SHIFT_AMT - 1)) 
                : extended_result;


        // Scaling
        assign scaled_result = biased_result >>> SHIFT_AMT;

        // Saturation
        always_comb begin
            if(scaled_result > MAX_OUT)
                pixel_out = MAX_OUT[15:0];
            else if(scaled_result < MIN_OUT)
                pixel_out = MIN_OUT[15:0];
            else
                pixel_out = scaled_result[15:0];
        end

        assign pixel_valid = relu_valid;
endmodule













// The choice is **rounding + arithmetic shifting + saturation** because it gives the best accuracy while still guaranteeing a valid 16-bit  output.

// ### Purpose of each stage

// #### 1. Shifting
// Purpose: **scale the accumulator result down to the output precision.**

// The convolution accumulator usually has more bits than the final output. If the accumulator is, for example, 32 bits but the output must be 16 bits, the value must be reduced.

// An arithmetic right shift:

// ```systemverilog
// scaled = result >>> SHIFT_AMT;
// ```

// divides the value by `2^SHIFT_AMT` while preserving the sign.

// Example:

// ```text
// result = 1024
// SHIFT_AMT  = 4
// output = 1024 >>> 4 = 64
// ```

// So shifting is used for **scaling/truncation**.

// ---

// #### 2. Rounding
// Purpose: **reduce precision loss caused by shifting.**

// If you only shift, low bits are discarded. This is equivalent to truncation, which introduces error.

// Example without rounding:

// ```text
// result = 7
// SHIFT_AMT  = 1
// 7 >>> 1 = 3
// ```

// But mathematically:

// ```text
// 7 / 2 = 3.5
// ```

// So truncation loses `0.5`.

// With rounding, you add half of the divisor before shifting:

// ```text
// rounded = (7 + 1) >>> 1 = 4
// ```

// This is closer to the ideal result.

// So rounding improves numerical accuracy and reduces average quantization error.

// ---

// #### 3. Saturation
// Purpose: **prevent overflow from producing invalid output values.**

// After scaling and rounding, the value may still be outside the 16-bit signed range:

// ```text
// minimum = -32768
// maximum = +32767
// ```

// If the value is too large, saturation forces it to the maximum:

// ```text
// value > 32767  → output = 32767
// ```

// If the value is too negative, saturation forces it to the minimum:

// ```text
// value < -32768 → output = -32768
// ```

// This is better than wraparound overflow, where a large positive number could incorrectly become negative.

// ---

// ### Why this choice is good

// The chosen method is:

// ```text
// rounding → arithmetic shift → saturation
// ```

// or equivalently, if rounding is done before shifting:

// ```text
// add rounding bias → arithmetic shift → saturation
// ```

// This choice is good because:

// 1. **It preserves sign correctly**  
//    Arithmetic right shift keeps negative values negative.

// 2. **It improves accuracy**  
//    Rounding gives a value closer to the true scaled result than pure truncation.

// 3. **It guarantees valid 16-bit signed output**  
//    Saturation ensures the result is always inside `[-32768, 32767]`.

// 4. **It is hardware-efficient**  
//    It only needs adders, shifters, and comparators. No DSPs or memory are required.

// 5. **It satisfies the competition requirement**  
//    The final output is at least 16-bit signed, and the handling of overflow, truncation, rounding, and saturation is clearly defined.

// ### Short justification

// Use **shifting** to scale the wide accumulator result, **rounding** to reduce truncation error, and **saturation** to prevent overflow. This gives the best practical tradeoff between precision, correctness, and hardware cost.

// ### Sources
// 1. Provided competition specification.  
// 2. Provided `output_formatter.sv` module specification.  
// 3. IEEE Std 1800-2017 SystemVerilog LRM: signed arithmetic shift `>>>`, signed comparisons, and bit-width extension rules.