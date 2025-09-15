module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output [WIDTH-1:0] edge_detect_pulse
);
    // TODO: implement a multi-bit edge detector that detects a rising edge of 'signal_in[x]'
    // and outputs a one-cycle pulse 'edge_detect_pulse[x]' at the next clock edge
    // Feel free to use as many number of registers you like

    // Remove this line once you create your edge detector
    reg [WIDTH-1:0] signal_in_d = 0;
    reg [WIDTH-1:0] rising_comd = 0;
    reg [WIDTH-1:0] edge_detect_pulse_reg = 0;
    assign edge_detect_pulse = edge_detect_pulse_reg;

    always @(posedge clk) begin
        signal_in_d[WIDTH-1:0] <= signal_in[WIDTH-1:0];
    end
    always @(*) begin
        rising_comd[WIDTH-1:0] = signal_in[WIDTH-1:0] & ~signal_in_d[WIDTH-1:0];
    end
    always @(posedge clk) begin
        edge_detect_pulse_reg[WIDTH-1:0] <= rising_comd[WIDTH-1:0];
    end


endmodule
