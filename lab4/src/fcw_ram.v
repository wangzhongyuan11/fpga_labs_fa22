module fcw_ram(
    input clk,
    input rst,
    input rd_en,
    input wr_en,
    input [1:0] addr,
    input [23:0] d_in,
    output reg [23:0] d_out
);
    reg [23:0] ram [3:0];

    always @(posedge clk) begin
        if (rst) begin
            ram[0] <= 24'h00EC3C; // 440 Hz
            ram[1] <= 24'h010905; // 494 Hz
            ram[2] <= 24'h01194B; // 523 Hz
            ram[3] <= 24'h013BCD; // 587 Hz
        end
        else if (wr_en)
            ram[addr] <= d_in;
    end

    always @(posedge clk) begin
        if (rd_en) begin
            d_out <= ram[addr];
        end
    end
endmodule
