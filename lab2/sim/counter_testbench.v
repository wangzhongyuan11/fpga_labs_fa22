`timescale 1ns/1ns

`define SECOND 1000000000
`define MS 1000000

module counter_testbench();
    reg clock = 0;
    reg ce ;
    wire [3:0] LEDS;

    counter ctr (
        .clk(clock),
        .ce(ce),
        .LEDS(LEDS)
    );

    // Notice that this code causes the `clock` signal to constantly
    // switch up and down every 4 time steps.
    always #(4) clock <= ~clock;

    initial begin
        `ifdef IVERILOG
            $dumpfile("counter_testbench.fst");
            $dumpvars(0, counter_testbench);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // TODO: Change input values and step forward in time to test
        // your counter and its clock enable/disable functionality.
        ce = 0;        // 关闭计数
        #10;           // 等待 10 时间单位
        
        ce = 1;        // 打开计数
        repeat (10) @(posedge clock); // 等待 10 个时钟上升沿
        $display("After 10 clocks with ce=1, LEDS = %b", LEDS);

        ce = 0;        // 关闭计数
        repeat (5) @(posedge clock);  // 等待 5 个时钟
        $display("With ce=0, LEDS should not change: %b", LEDS);

        ce = 1;        // 再次打开计数
        repeat (40) @(posedge clock);
        $display("After re-enable ce, LEDS = %b", LEDS);



        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule

