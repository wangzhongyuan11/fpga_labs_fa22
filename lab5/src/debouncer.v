module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output [WIDTH-1:0] debounced_signal
);
    // TODO: fill in neccesary logic to implement the wrapping counter and the saturating counters
    // Some initial code has been provided to you, but feel free to change it however you like
    // One wrapping counter is required
    // One saturating counter is needed for each bit of glitchy_signal
    // You need to think of the conditions for reseting, clock enable, etc. those registers
    // Refer to the block diagram in the spec

    // Remove this line once you have created your debouncer
    reg [WRAPPING_CNT_WIDTH-1:0] sample_cnt = 0;
    reg [SAT_CNT_WIDTH-1:0] saturating_counter [WIDTH-1:0];


    integer k;
    initial begin
      for (k = 0; k < WIDTH; k = k + 1) begin
        saturating_counter[k] = 0;
      end
    end

    always @(posedge clk) begin
        if(sample_cnt == SAMPLE_CNT_MAX)
            sample_cnt <= 0;
        else 
            sample_cnt <= sample_cnt + 1'b1;
    end

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin:saturatingcounter
            always @(posedge clk) begin
                if(sample_cnt == SAMPLE_CNT_MAX) begin
                    if(glitchy_signal[i])
                        if(saturating_counter[i] == PULSE_CNT_MAX)
                            saturating_counter[i] <= saturating_counter[i];
                        else
                            saturating_counter[i] <= saturating_counter[i] + 1'b1;
                    else
                        saturating_counter[i] <= 0;
                end
                else
                    saturating_counter[i] <= saturating_counter[i];
            end
            assign debounced_signal[i] = (saturating_counter[i] >= (PULSE_CNT_MAX)) ? 1'b1 : 1'b0;
        end
    endgenerate
endmodule
