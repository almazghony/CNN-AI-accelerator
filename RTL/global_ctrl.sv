module global_ctrl
(
    input  logic    clk,
    input  logic    rst_n,
    input  logic    start,
    input  logic    output_done,
    output logic    done,
    output logic    processing_en
);

    typedef enum logic [1:0] {
        IDLE,
        PROCESSING,
        DONE
    } state_t;

    state_t cs, ns;

    // state register
    always_ff @(posedge clk) begin
        if (!rst_n) cs <= IDLE;
        else        cs <= ns;
    end

    // next state logic
    always_comb begin
        case (cs)
            IDLE:       ns = (start)       ? PROCESSING : IDLE;
            PROCESSING: ns = (output_done) ? DONE       : PROCESSING;
            DONE:       ns = IDLE;
            default:    ns = IDLE;
        endcase
    end

    // output logic
    always_comb begin
        case (cs)
            IDLE:       begin processing_en = 1'b0; done = 1'b0; end
            PROCESSING: begin processing_en = 1'b1; done = 1'b0; end
            DONE:       begin processing_en = 1'b0; done = 1'b1; end
            default:    begin processing_en = 1'b0; done = 1'b0; end
        endcase
    end

endmodule
