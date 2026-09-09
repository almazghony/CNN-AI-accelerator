module global_ctrl
(
	input   wire    logic    clk, 
	input   wire    logic    rst_n, 
	input   wire    logic    start, 
	input   wire    logic    output_done,
	output          logic    busy, 
	output          logic    done,
    output          logic    processing_en
);

    typedef enum logic [1:0] {
        IDLE,
        PROCESSING,
        DONE
    } state_t;

	state_t cs, ns;

    // state register
	always_ff@(posedge clk) begin
		if(!rst_n) cs<=IDLE;
		else cs<=ns;
	end
	
    //next state logic
    always_comb begin
        case (cs)
            IDLE:
                ns = (start)? PROCESSING : IDLE;

            PROCESSING: 
                ns = (output_done)? DONE : PROCESSING;

            DONE: 
                ns = IDLE;
        endcase
    end


    //output logic
    always_comb begin
        case(cs)
            IDLE: begin
                processing_en = 0;
                done          = 0;
                busy          = 0;
            end

            PROCESSING: begin
                processing_en = 1;
                busy          = 1;
                done          = 0;
            end

            DONE: begin
                processing_en = 0;
                busy          = 0;
                done          = 1;
            end

            default: begin
                processing_en = 0;
                busy          = 0;
                done          = 0;
            end
        endcase
    end
endmodule
