module fsm #(
    parameter CYCLES_PER_SECOND = 125_000_000,
    parameter WIDTH = $clog2(CYCLES_PER_SECOND)
)(
    input clk,
    input rst,
    input [2:0] buttons,
    output [3:0] leds,
    output reg [23:0] fcw,
    output [1:0] leds_state
);
    localparam REGULAR_PLAY = 2'b00;
    localparam REVERSE_PLAY = 2'b01;
    localparam PAUSED = 2'b10;
    localparam EDIT = 2'b11;

    reg [1:0] addr = 0;
    reg wr_en;
    reg rd_en = 1;
    reg [23:0] d_in;
    wire [23:0] d_out;
    reg [23:0] data_now;
    reg [1:0] present_state = REGULAR_PLAY;
    reg [1:0] next_state = REGULAR_PLAY;
    reg [WIDTH-1:0] clk_counter = 0;

    fcw_ram notes (
        .clk(clk),
        .rst(rst),
        .rd_en(rd_en),
        .wr_en(wr_en),
        .addr(addr),
        .d_in(d_in),
        .d_out(d_out)
    );

    always @(posedge clk) begin
        if (rst) present_state <= REGULAR_PLAY;
        else present_state <= next_state;
        clk_counter <= clk_counter + 1;

        case (present_state)
            REGULAR_PLAY: begin
                if (buttons[0]) next_state <= PAUSED;
                else if (buttons[1]) next_state <= REVERSE_PLAY;
            end

            REVERSE_PLAY: begin
                if (buttons[0]) next_state <= PAUSED;
                else if (buttons[1]) next_state <= REGULAR_PLAY;
            end

            PAUSED: begin
                if (buttons[0]) next_state <= REGULAR_PLAY;
                else if (buttons[2]) begin
                    next_state <= EDIT;
                    rd_en <= 1;
                    wr_en <= 0;
                    fcw <= d_out;
                end
            end

            EDIT: begin
                if (buttons[2]) next_state <= PAUSED;
            end

        endcase

    case (present_state)
        REGULAR_PLAY: begin
            wr_en <= 0;
            if (clk_counter == 0) begin
                addr <= (addr == 3) ? 0 : (addr + 1);
                rd_en <= 1;
            end
            fcw <= d_out;
        end

        REVERSE_PLAY: begin
            wr_en <= 0;
            if (clk_counter == 0) begin
                addr <= (addr == 0) ? 3 : (addr - 1);
                rd_en <= 1;
            end
            fcw <= d_out;
        end

        PAUSED: begin
            fcw <= 0;
        end

        EDIT: begin   
            if (buttons[0]) begin
                rd_en <= 0;
                wr_en <= 1;
                fcw <= (fcw <= 4000)? 1375181 : (fcw + 1000);
                d_in <= (fcw <= 4000)? 1375181 : (fcw + 1000);
            end else if (buttons[1]) begin
                rd_en <= 0;
                wr_en <= 1;
                fcw <= (fcw >= 1370000)? 2750 : (fcw - 1000);
                d_in <= (fcw >= 1370000)? 2750 : (fcw - 1000);
            end else begin
                rd_en <= 1;
                wr_en <= 0;
                fcw <= d_out;
            end
        end
    endcase
    end

    assign leds_state = present_state;
    assign leds[3] = (addr == 3);
    assign leds[2] = (addr == 2);
    assign leds[1] = (addr == 1);
    assign leds[0] = (addr == 0);

endmodule