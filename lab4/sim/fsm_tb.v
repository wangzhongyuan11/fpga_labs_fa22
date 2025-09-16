`timescale 1ns/1ns
`define CLK_PERIOD 8

module fsm_tb();
    // Generate 125 MHz clock
    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    // I/O
    reg rst;
    reg [2:0] buttons;
    wire [23:0] fcw;
    wire [3:0] leds;
    wire [1:0] leds_state;

    fsm #(.CYCLES_PER_SECOND(1)) DUT (
        .clk(clk),
        .rst(rst),
        .buttons(buttons),
        .leds(leds),
        .leds_state(leds_state),
        .fcw(fcw)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("fsm_tb.fst");
            $dumpvars(0, fsm_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        rst = 1;
        @(posedge clk); #1;
        rst = 0;

        buttons = 0;

        // TODO: Toggle the buttons
        // Verify state transitions with the LEDs
        // Verify fcw is being set properly by the FSM

        //press buttons[1] to transit into reverse state
        buttons[1] = 1; 
        @(posedge clk); #1;
        buttons[1] = 0;
        #32;
        assert(leds_state == 2'b01) else $error("leds_state should be 01");
      #1250;
        //assert(fcw == 67934) else $error("fcw should be 67934");


        //press buttons[0] to transit into pause state
        buttons[0] = 1; 
        @(posedge clk); #1;
        buttons[0] = 0;
        #32;
        assert(leds_state == 2'b10) else $error("leds_state should be 10");
        assert(fcw == 0) else $error("fcw should be 0");


        //press buttons[2] to transit into edit state
        buttons[2] = 1; 
        @(posedge clk); #1;
        buttons[2] = 0;
        #64;
        assert(leds_state == 2'b11) else $error("leds_state should be 11");
        //assert(fcw == 67934) else $error("fcw should be 67934");

        //increase frequency
        repeat (2) begin
            buttons[0] = 1; 
            @(posedge clk); #8;
            buttons[0] = 0;
            #32;
        end
       // assert(fcw == 69934) else $error("fcw should be 69934");
        assert(leds_state == 2'b11) else $error("leds_state should be 11");

        //back to regular play
        buttons[2] = 1; 
        @(posedge clk); #8;
        buttons[2] = 0; #8;
        buttons[0] = 1; 
        @(posedge clk); #8;
        buttons[0] = 0;
        #64;
        //assert(fcw == 69934) else $error("fcw should be 69934");

        rst = 1;  // Trigger reset
        @(posedge clk); #8;  // Wait for one clock cycle
        rst = 0;
        #64;
        assert(leds_state == 2'b00) else $error("leds_state should be 01");
        // $display("leds is %b", leds_state);


        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule