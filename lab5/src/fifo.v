module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output reg [WIDTH-1:0] dout,
    output empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [POINTER_WIDTH-1:0] read_ptr, write_ptr;  // read and write pointer
    reg [POINTER_WIDTH:0] fifo_count;

    // full & empty
    assign full = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);

    // write
    always @(posedge clk) begin
        if (rst) begin
            write_ptr <= 1'b0;
        end else if (wr_en && !full) begin
            mem[write_ptr] <= din;
            write_ptr <= write_ptr + 1;
        end
    end

    // read
    always @(posedge clk) begin
        if (rst) begin
            read_ptr <= 1'b0;
        end else if (rd_en && !empty) begin
            dout <= mem[read_ptr];
            read_ptr <= read_ptr + 1;
        end
    end

    // follow how many data is available in fifo
    always @(posedge clk) begin
        if (rst) begin
            fifo_count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b01: fifo_count <= (empty) ? fifo_count : (fifo_count - 1);  // read only
                2'b10: fifo_count <= (full) ? fifo_count : (fifo_count + 1);  // write only
                default: fifo_count <= fifo_count;      // read and write at the same time
            endcase
        end
    end
/*
    // Assertion: When the FIFO is full, the write pointer should not change on wr_en
    property write_pointer_stable_when_full;
        @(posedge clk) full && wr_en |-> (write_ptr == $past(write_ptr));
    endproperty
    assert property (write_pointer_stable_when_full) else $error("Error: write pointer changed when FIFO was full");

    // Assertion: When the FIFO is empty, the read pointer should not change on rd_en
    property read_pointer_stable_when_empty;
        @(posedge clk) empty && rd_en |-> (read_ptr == $past(read_ptr));
    endproperty
    assert property (read_pointer_stable_when_empty) else $error("Error: read pointer changed when FIFO was empty");

    // Assertion: When reset is asserted, read and write pointers are set to 0, and full is deasserted
    property reset_behavior;
        @(posedge clk) rst |=> (read_ptr == 0 && write_ptr == 0 && !full);
    endproperty
    assert property (reset_behavior) else $error("Error: read/write pointers were not reset or full signal was not deasserted");

*/

endmodule