module sq_wave_gen (
    input clk,
    input next_sample,
    output [9:0] code
);
    localparam high_low_switch_COUNT = 139;
    localparam HIGH_S = 1;
    localparam HIGH_CODE = 562;
    localparam LOW_S = 0;
    localparam LOW_CODE = 462;
    reg [$clog2(high_low_switch_COUNT)-1:0] dac_next_sample_cnt = 0;
    reg code_state_r = LOW_S;

    always @(posedge clk) begin
        if (next_sample == 1'b1)
            dac_next_sample_cnt <=  (dac_next_sample_cnt == high_low_switch_COUNT) ? 0:dac_next_sample_cnt + 1;
        else
            dac_next_sample_cnt <= dac_next_sample_cnt;
        if (dac_next_sample_cnt == high_low_switch_COUNT)
            code_state_r <= ~code_state_r;
        else
            code_state_r <= code_state_r;
    end    

    assign code = code_state_r == HIGH_S ? HIGH_CODE : LOW_CODE;
endmodule