module counter (
  input clk,
  input ce,
  output [3:0] LEDS
);
    // Some initial code has been provided for you
    // You can change this code if needed
    reg [3:0] led_cnt_value=0;
    assign LEDS = led_cnt_value;

    // TODO: Instantiate a reg net to count the number of cycles
    // required to reach one second. Note that our clock period is 8ns.
    // Think about how many bits are needed for your reg.
    reg [27:0] second_cnt=0; // 2^28 = 268435456 > 125000000

    always @(posedge clk) begin
        // TODO: update the reg if clock is enabled (ce is 1).
        // Once the requisite number of cycles is reached, increment the count.
        if(ce)
            second_cnt <= second_cnt + 1'b1;
        else
            second_cnt <= second_cnt;
        if(second_cnt == 27'd2) begin
            second_cnt <= 27'd0;
            if(led_cnt_value == 4'b1111)
                led_cnt_value <= 4'd0;
            else
                led_cnt_value <= led_cnt_value + 1'b1;
        end
    end
endmodule

