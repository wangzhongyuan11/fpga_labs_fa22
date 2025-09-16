module nco(
    input clk,
    input rst,
    input [23:0] fcw,
    input next_sample,
    output [9:0] code
);
    reg [9:0] sine_lut [0:255];
    initial begin
        $readmemb("sine.bin", sine_lut);
    end

    reg [23:0] pa = 0;
    always @(posedge clk) begin
        if (rst) begin
            pa <= 0;
        end else if (next_sample) begin
            pa <= pa + fcw;
        end
    end

    assign code = sine_lut[pa[23:16]];
endmodule
