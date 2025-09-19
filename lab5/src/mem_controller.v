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
  output reg[FIFO_WIDTH-1:0] dout,
  output [5:0] state_leds
);

  localparam MEM_WIDTH = 8; // Width of each mem entry (word)
  localparam MEM_DEPTH = 256; // Number of entries
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

  always @(posedge clk) begin
    // State reg update
    if (rst) curr_state <= IDLE;
    else curr_state <= next_state;
  end

  reg [2:0] pkt_rd_cnt;
  reg [MEM_WIDTH-1:0] cmd;
  reg [MEM_WIDTH-1:0] addr;
  reg [MEM_WIDTH-1:0] data;
  reg handshake;


  always @(*) begin
    // Initial values to avoid latch synthesis
    next_state = curr_state;

    case (curr_state)
      // Next state logic
      IDLE: begin
        if(!rx_fifo_empty) next_state = READ_CMD;
      end

      READ_CMD: begin
        if(!rx_fifo_empty) next_state = READ_ADDR;
      end

      READ_ADDR: begin
        if (cmd == 8'd49) begin
          if(!rx_fifo_empty) begin 
            next_state = READ_DATA;  //write command
          end 
        end else if (cmd == 8'd48)begin
          next_state = READ_MEM_VAL; //read command
        end
      end

      READ_DATA: begin
          next_state = WRITE_MEM_VAL;
      end

      READ_MEM_VAL: begin
        next_state = ECHO_VAL;
      end

      ECHO_VAL: begin
        if (!tx_fifo_full) begin
          next_state = IDLE;
        end
        
      end

      WRITE_MEM_VAL: begin
        next_state = IDLE;
      end
    endcase

  end

  always @(*) begin
    // Initial values to avoid latch synthesis
    mem_we = 1'b0;           // Default: no memory write
    rx_fifo_rd_en = 1'b0;     // Default: no FIFO read
    tx_fifo_wr_en = 1'b0;     // Default: no FIFO write
    mem_addr = addr;          // Set memory address from the address register
    mem_din = data;           // Set memory data from the data register
    dout = 0;

    case (curr_state)
    // Output and mem signal logic
      IDLE: begin
        if (!rx_fifo_empty) rx_fifo_rd_en = 1'b1;
      end

      READ_CMD: begin
        rx_fifo_rd_en = 1'b1;
        //cmd = din;
      end

      READ_ADDR: begin
        if(cmd == 8'd49) begin
          rx_fifo_rd_en = 1'b1;
        end else rx_fifo_rd_en = 1'b0;
        //addr = din;
        mem_addr = addr;
      end

      READ_DATA: begin
        rx_fifo_rd_en = 1'b1;
        //data = din;
      end

      READ_MEM_VAL: begin
        rx_fifo_rd_en = 1'b0;
        tx_fifo_wr_en = 1'b0;
        
      end

      ECHO_VAL: begin
        rx_fifo_rd_en = 1'b0;
        tx_fifo_wr_en = 1'b1;   // Write the memory value to the tx_fifo
        dout = mem_dout;        // Output data from memory to the FIFO
      end

      WRITE_MEM_VAL: begin
        mem_we = 1'b1;      // Enable memory write
        mem_addr = addr;    // Set memory address
        mem_din = data;     // Set memory data from the data byte
      end
    endcase

  end



  always @(posedge clk) begin
    // Byte reading and packet counting
      case (curr_state)
        READ_CMD: begin
          cmd <= din;               // Read the command byte from FIFO
        end

        READ_ADDR: begin
          addr <= din;         // Read the address byte from FIFO
        end

        READ_DATA: begin
          data <= din;               // Read the data byte from FIFO                  
        end
      endcase
  end

  // TODO: MODIFY THIS
  assign state_leds = {2'b00, curr_state};

endmodule