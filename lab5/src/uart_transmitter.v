module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200
)(
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

    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;
    reg [3:0] bit_counter;
    reg [9:0] tx_shift;          // Shift register to hold start, data, and stop bits
    reg tx_running;
    wire symbol_edge;

    //--|Signal Assignments|------------------------------------------------------
    assign symbol_edge = (clock_counter == (SYMBOL_EDGE_TIME - 1));
    assign data_in_ready = !tx_running;
    assign serial_out = tx_shift[0];

    //--|Counters|----------------------------------------------------------------

    always @ (posedge clk) begin
        clock_counter <= (!tx_running || reset || symbol_edge) ? 0 : clock_counter + 1;
    end


    // Counts down from 9 to 0
    always @(posedge clk) begin
        if (reset) begin
            bit_counter <= 0;
            tx_running <= 0;
        end else if (data_in_valid && !tx_running) begin
            bit_counter <= 9;
            tx_running <= 1;
        end else if (symbol_edge && tx_running) begin
            if (bit_counter == 0) begin
                tx_running <= 0;
            end else begin
                bit_counter <= bit_counter - 1;
            end
        end
    end

    //--|Shift Register|----------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            tx_shift <= 10'b1111111111; // Idle state (UART line high)
        end else if (symbol_edge && tx_running) begin
            tx_shift <= {1'b1, tx_shift[9:1]}; // Shift right with LSB first
        end else if (data_in_valid && !tx_running) begin
            tx_shift <= {1'b1, data_in, 1'b0}; // {Stop bit, Data, Start bit}
        end
    end

/*
    // Assertion: When not transmitting, data_in_ready and serial_out should both be high
    property not_transmitting;
        @(posedge clk) !tx_running |=> (data_in_ready == !tx_running) && (serial_out == !tx_running) ;
    endproperty

    assert property (not_transmitting) else $error("Error: data_in_ready or serial_out is not high when not transmitting");

    // Assertion: When transmitting, data_in_ready should be low for exactly (CLOCK_FREQ / BAUD_RATE) * 10 cycles
    property transmitting;
        @(posedge clk) tx_running |-> ##[0:((SYMBOL_EDGE_TIME * 10) - 1)] !data_in_ready;
    endproperty

    assert property (transmitting) else $error("Error: data_in_ready did not stay low for the correct duration during transmission");
*/
endmodule