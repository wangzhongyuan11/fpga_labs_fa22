module mem_controller #(
  parameter FIFO_WIDTH = 8
) (
  input clk,
  input rst,
  input rx_fifo_empty,
  input tx_fifo_full,
  input [FIFO_WIDTH-1:0] din,

  output reg rx_fifo_rd_en,
  output reg tx_fifo_wr_en,
  output reg [FIFO_WIDTH-1:0] dout,
  output [5:0] state_leds
);

  localparam MEM_WIDTH = 8;   /* Width of each mem entry (word) */
  localparam MEM_DEPTH = 256; /* Number of entries */
  localparam NUM_BYTES_PER_WORD = MEM_WIDTH/8;
  localparam MEM_ADDR_WIDTH = $clog2(MEM_DEPTH); 

  reg [NUM_BYTES_PER_WORD-1:0] mem_we = 0;
  reg [MEM_ADDR_WIDTH-1:0] mem_addr;
  reg [MEM_WIDTH-1:0] mem_din;
  wire [MEM_WIDTH-1:0] mem_dout;

  memory #(
    .MEM_WIDTH(MEM_WIDTH),
    .DEPTH(MEM_DEPTH)
  ) mem(
    .clk(clk),
    .en(1'b1),
    .we(mem_we),
    .addr(mem_addr),
    .din(mem_din),
    .dout(mem_dout)
  );

  localparam 
    IDLE = 3'd0,
    READ_CMD = 3'd1,
    READ_ADDR = 3'd2,
    READ_DATA = 3'd3,
    READ_MEM_VAL = 3'd4,
    ECHO_VAL = 3'd5,
    WRITE_MEM_VAL = 3'd6;

  reg [2:0] curr_state;
  reg [2:0] next_state;



  reg [MEM_WIDTH-1:0] cmd;
  reg [MEM_WIDTH-1:0] addr;
  reg [MEM_WIDTH-1:0] data;

  reg rx_fifo_empty_r;
  always @(posedge clk) begin
    rx_fifo_empty_r <= rx_fifo_empty;
  end

  always @(*) begin
    case (curr_state)
      /* next state logic */
      IDLE:begin
        if(~rx_fifo_empty) begin
          next_state = READ_CMD;
          rx_fifo_rd_en = 1'b1;
        end
        else next_state = IDLE;
        
        tx_fifo_wr_en = 0;
        mem_we = 0;
      end
      READ_CMD:begin
        next_state = READ_ADDR;
        if(rx_fifo_empty) rx_fifo_rd_en = 0;
        else begin
          rx_fifo_rd_en = 1;
        end

        cmd = din;
      end
      READ_ADDR:begin
        if(~rx_fifo_empty_r && cmd == 8'd49) next_state = READ_DATA;
        else if(cmd == 8'd48) begin
          next_state = READ_MEM_VAL;
          rx_fifo_rd_en = 0;
          mem_addr = addr;
        end
        else next_state = READ_ADDR;
        
        if(rx_fifo_empty || cmd == 8'd48) rx_fifo_rd_en = 0;
        else begin
          rx_fifo_rd_en = 1;
        end

        addr = din;
      end
      READ_MEM_VAL:begin
        next_state = ECHO_VAL;

        rx_fifo_rd_en = 0;
        data = mem_dout;
      end
      READ_DATA:begin
        if(~rx_fifo_empty_r) next_state = WRITE_MEM_VAL;
        if(rx_fifo_empty) rx_fifo_rd_en = 0;
        else begin
          rx_fifo_rd_en = 1;
        end

        data = din;
      end
      WRITE_MEM_VAL:begin
        next_state = IDLE;

        rx_fifo_rd_en = 1'b0;
        mem_addr = addr;
        mem_din = data;
        mem_we = 1'b1;
      end
      ECHO_VAL:begin
        next_state = IDLE;

        dout = data;
        rx_fifo_rd_en = 0;
        tx_fifo_wr_en = 1'b1;
      end

    endcase
  end


  always @(posedge clk) begin
    /* byte reading and packet counting */
    if(rst) begin
      next_state <= IDLE;
      curr_state <= IDLE;
      rx_fifo_rd_en <= 1'b0;
      tx_fifo_wr_en <= 1'b0;
    end
    else begin
      curr_state <= next_state;
    end
      
  end

  assign state_leds[5:0] = {3'b0, curr_state[2:0]};

endmodule