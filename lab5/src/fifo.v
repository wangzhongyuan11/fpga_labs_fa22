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
    reg [WIDTH-1:0] fifo_buffer[DEPTH - 1 : 0];
    reg [$clog2(DEPTH)-1:0]	wr_addr;
    reg [$clog2(DEPTH)-1:0]	rd_addr;
    reg	[$clog2(DEPTH):0] fifo_cnt;

    //read
    always @ (posedge clk) begin
        if(rst) begin
            rd_addr <= 0;
            dout <= 0;
        end  
        else if(!empty && rd_en)begin
            rd_addr <= rd_addr + 1'd1;
            dout <= fifo_buffer[rd_addr];
        end
    end

    //write
    always @ (posedge clk) begin
        if(rst) begin
            wr_addr <= 0;
        end
        else if(!full && wr_en)begin
            fifo_buffer[wr_addr] <= din;
            wr_addr <= wr_addr + 1'd1;
        end
    end

    //count
    always @ (posedge clk) begin
        if(rst)
            fifo_cnt <= 0;
        else begin
            case({wr_en,rd_en})						
                2'b00:fifo_cnt <= fifo_cnt;			
                2'b01:	                            
                    if(fifo_cnt != 0)
                        fifo_cnt <= fifo_cnt - 1'b1;
                2'b10:                              
                    if(fifo_cnt != DEPTH)
                        fifo_cnt <= fifo_cnt + 1'b1;
                2'b11:fifo_cnt <= fifo_cnt;	        
                default:;                              	
            endcase
        end
    end
    
    assign full  = (fifo_cnt == DEPTH) ? 1'b1 : 1'b0;
    assign empty = (fifo_cnt == 0)? 1'b1 : 1'b0;

    

endmodule
