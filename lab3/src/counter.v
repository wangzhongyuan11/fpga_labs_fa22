module counter #(
    parameter CYCLES_PER_SECOND = 10
)(
    input clk,
    input [3:0] buttons,
    output [3:0] leds
);
    reg [3:0] counter = 0;
    assign leds = counter;
    reg running = 1'b0;
    reg [4:0] second_cnt = 0;
    
    always @(posedge clk) begin
        running = buttons[2];
        if(!running) begin
            if (buttons[0])
                counter <= counter + 4'd1;
            else if (buttons[1])
                counter <= counter - 4'd1;
            else if (buttons[3])
                counter <= 4'd0;
            else
                counter <= counter;
        end

        else if (second_cnt == CYCLES_PER_SECOND - 1) begin
            counter <= counter + 4'd1;
        end
        else
            counter <= counter;
    end

    always @(posedge clk) begin
        if (running)
            second_cnt <= second_cnt + 1'b1;
        else
            second_cnt <= second_cnt;
        if(second_cnt == CYCLES_PER_SECOND - 1) begin
            second_cnt <= 0;
        end
    end


endmodule

