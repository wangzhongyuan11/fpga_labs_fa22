module sq_wave_gen #(
    parameter STEP = 12'd10
)(
    input clk,
    input rst,
    input next_sample,
    input [2:0] buttons,
    output reg [9:0] code,
    output [3:0] leds
);
    localparam HIGH_VALUE = 10'd562;
    localparam LOW_VALUE = 10'd462;
    reg [11:0] COUNT_MAX = 12'd139; //to support 20Hz, we need 12 digits
    reg [11:0] sample_counter = 0;
    reg wave_state = 0;
    reg mode = 0; //0 = linear, 1 = exponential


    always @(posedge clk) begin
        if (rst) begin
            // todo: registers reset, wave freq to 440Hz
            COUNT_MAX <= 139;
            sample_counter <= 0;
            wave_state <= 0;
        end
        else begin
            if (buttons[2]) mode <= ~mode;

            if (buttons[1]) begin
                if (mode) COUNT_MAX <= (COUNT_MAX <= 1530) ? (COUNT_MAX << 1) : 6;
                else COUNT_MAX <= (COUNT_MAX <= 3060 - STEP) ? (COUNT_MAX + STEP) : 6;
            end else if (buttons[0]) begin
                if (mode) COUNT_MAX <= (COUNT_MAX >= 10) ? (COUNT_MAX >> 1) : 3058;
                else COUNT_MAX <= (COUNT_MAX >= 6 + STEP) ? (COUNT_MAX - STEP) : 3058;
            end
            else begin
                COUNT_MAX <= COUNT_MAX;
            end

            if (next_sample) begin
                if (sample_counter >= COUNT_MAX - 1) begin
                    sample_counter <= 0;
                    wave_state <= ~wave_state; 
                end else begin
                    sample_counter <= sample_counter + 1;
                end
            end
            else begin
                sample_counter <= sample_counter;
            end

            if (wave_state) begin
                code <= HIGH_VALUE;
            end else begin
                code <= LOW_VALUE;
            end

        end
    end

    assign leds[0] = mode;
endmodule