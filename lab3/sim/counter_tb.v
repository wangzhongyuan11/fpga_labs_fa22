`timescale 1ns/1ns

`define CLK_PERIOD 8

module counter_tb();
    // Generate clock
    reg clk = 0;
    reg [3:0] buttons, leds;
    always #(`CLK_PERIOD/2) clk = ~clk;

    counter #(
        .CYCLES_PER_SECOND(1)
    ) cnt0 (
        .clk(clk),
        .buttons(buttons),
        .leds(leds)
    );

    integer i;
    initial begin
        `ifdef IVERILOG
            $dumpfile("counter_tb.fst");
            $dumpvars(0, counter_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        //@(posedge clk)
        // counter up
        buttons = 4'b0100;
        for (i=0; i<20; i=i+1) begin
            if(leds != i%5'b10000) begin
                $error("Failure 2 LEDs should be: %x, but it is %x", i%5'b10000, leds);
            end
            @(posedge clk); #(1);
        end

        // counter down
        buttons = 4'b0010;
        for (i=20; i>10; i=i-1) begin
            if(leds != i%5'b10000) begin
                $error("Failure 1: LEDs should be: %x, but it is %x", i%5'b10000, leds);
            end
            @(posedge clk); #(1);
        end

        // reset
        buttons = 4'b1000;
        @(posedge clk); #(1);
        if(leds != 4'b0000) begin
            $error("Failure 2: leds should be: 4'b0000, but it is %x", leds);
        end

        #20
        `ifndef IVERILOG
        $vcdplusoff;
        `endif
        $finish();
    end
endmodule