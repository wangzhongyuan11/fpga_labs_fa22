module dac #(
    parameter CYCLES_PER_WINDOW = 1024,
    parameter CODE_WIDTH = $clog2(CYCLES_PER_WINDOW)
)(
    input clk,
    input [CODE_WIDTH-1:0] code,
    output next_sample,
    output pwm
);
    reg pwm_r = 0;
    reg [CODE_WIDTH-1:0] cnt = 0 ;
    reg [CODE_WIDTH-1:0] code_r = 0;
    reg [CODE_WIDTH-1:0] code_cnt = 0;

    always @(posedge clk) begin
        if(code_cnt == CYCLES_PER_WINDOW)
            code_cnt <= 0;
        else
            code_cnt <= code_cnt + 1;
    end

    always @(*) begin
        if(code_r == 0)
            pwm_r = 0;
        else
            pwm_r = (code_cnt <= code_r) ? 1'b1 : 1'b0;
    end

    always @(posedge clk) begin
        code_r <= code;
    end

    assign next_sample = (code_cnt == (CYCLES_PER_WINDOW-1));
    assign pwm = pwm_r;

endmodule