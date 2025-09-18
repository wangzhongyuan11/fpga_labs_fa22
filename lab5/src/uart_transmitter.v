module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);
    // See diagram in the lab guide
    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);

    reg [CLOCK_COUNTER_WIDTH-1:0] tx_sample_cntr;

    always @(posedge clk) begin
        if((reset) || (tx_sample_cntr == 0)) 
            tx_sample_cntr <= SYMBOL_EDGE_TIME - 1'b1;
        else 
            tx_sample_cntr <= tx_sample_cntr - 1'b1;
    end

    reg [9:0] tx_shifter;
    wire tx_do_sample;
    reg uart_txd, data_in_ready_r;
    assign serial_out = uart_txd;
    assign data_in_ready = data_in_ready_r;
    assign tx_do_sample = (tx_sample_cntr[CLOCK_COUNTER_WIDTH-1:0] == 0);

    always @(posedge clk) begin
        if(reset) begin
            tx_shifter <= 10'd0;
            uart_txd <= 1'b1;
            data_in_ready_r <= 1'b1;
        end
        else begin
            if(data_in_ready_r) begin
                if(data_in_valid) begin
                    data_in_ready_r <= 1'b0;
                    tx_shifter <= {1'b1, data_in[7:0], 1'b0};
                end
            end
            else begin
                if(tx_do_sample) begin
                    {tx_shifter, uart_txd} <= {tx_shifter, uart_txd} >> 1;
                    if(~|tx_shifter[9:1]) begin
                        data_in_ready_r <= 1'b1;
                    end
                end
            end
        end
    end
    
endmodule
