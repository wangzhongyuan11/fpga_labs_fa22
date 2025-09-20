module fixed_length_piano #(
    parameter CYCLES_PER_SECOND = 125_000_000
) (
    input clk,
    input rst,

    input [2:0] buttons,
    output [5:0] leds,

    // UART TX FIFO
    output reg [7:0] ua_tx_din,
    output reg ua_tx_wr_en,
    input ua_tx_full,

    // UART RX FIFO
    input [7:0] ua_rx_dout,
    input ua_rx_empty,
    output reg ua_rx_rd_en,

    // 输出给 NCO
    output reg [23:0] fcw
);

    // ==============================
    // 1. Note length 控制
    // ==============================
    localparam DEFAULT_NOTE_LEN = CYCLES_PER_SECOND / 5;
    reg [31:0] note_length = DEFAULT_NOTE_LEN;

    always @(posedge clk) begin
        if (rst) begin
            note_length <= DEFAULT_NOTE_LEN;
        end else begin
            if (buttons[0]) note_length <= note_length + (CYCLES_PER_SECOND / 20);
            if (buttons[1] && note_length > (CYCLES_PER_SECOND / 20))
                note_length <= note_length - (CYCLES_PER_SECOND / 20);
        end
    end

    // ==============================
    // 2. ROM 查表：ASCII → FCW
    // ==============================
    wire [23:0] rom_fcw;
    wire [7:0] last_address1;
    piano_scale_rom rom_inst (
        .address(ua_rx_dout),  // ASCII 字符作为地址
        .data(rom_fcw),
        .last_address(last_address1)
    );

    // ==============================
    // 3. FSM 定义
    // ==============================
    typedef enum logic [2:0] {
        S_IDLE  = 3'd0,
        S_READ  = 3'd1,
        S_ECHO  = 3'd2,
        S_PLAY  = 3'd3,
        S_DONE  = 3'd4
    } state_t;

    state_t state, next_state;

    reg [31:0] counter;
    reg [7:0] cur_char;

    // 状态转移
    always @(posedge clk) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // 下一个状态逻辑
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:  if (!ua_rx_empty) next_state = S_READ;
            S_READ:  next_state = S_ECHO;
            S_ECHO:  if (!ua_tx_full) next_state = S_PLAY;
            S_PLAY:  if (counter == 0) next_state = S_DONE;
            S_DONE:  next_state = S_IDLE;
        endcase
    end

    // ==============================
    // 4. 状态动作
    // ==============================
    always @(posedge clk) begin
        if (rst) begin
            ua_rx_rd_en <= 0;
            ua_tx_wr_en <= 0;
            fcw <= 0;
            counter <= 0;
            cur_char <= 0;
        end else begin
            ua_rx_rd_en <= 0;
            ua_tx_wr_en <= 0;

            case (state)
                S_IDLE: begin
                    fcw <= 0; // 空闲时不输出音符
                end

                S_READ: begin
                    ua_rx_rd_en <= 1;     // 读 FIFO
                    cur_char <= ua_rx_dout;
                end

                S_ECHO: begin
                    if (!ua_tx_full) begin
                        ua_tx_din <= cur_char;
                        ua_tx_wr_en <= 1; // 写 TX FIFO 回显
                    end
                end

                S_PLAY: begin
                    if (counter == 0) begin
                        fcw <= rom_fcw;   // 开始播放音符
                        counter <= note_length;
                    end else begin
                        counter <= counter - 1;
                    end
                end

                S_DONE: begin
                    fcw <= 0; // 播放结束
                end
            endcase
        end
    end

    // ==============================
    // 5. 调试 LED
    // ==============================
    assign leds = { (state == S_PLAY), note_length[25:21] };

endmodule
