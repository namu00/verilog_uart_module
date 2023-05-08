/*
    Writer: namu00
    Github: https://github.com/namu00/verilog_uart_module

    Target Clock: 50Mhz
    Module Description: UART TX module (NO Parity bit)
*/

module uart_tx#(
    parameter CLOCK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input clk,
    input n_rst,
    input uart_in_valid,
    input [7:0] uart_in,

    output serial_out,
    output tx_ready
);

    //CLOCK / BAUD_RATE == Cycle / Bit
    localparam SAMPLE_TIME = CLOCK_FREQ / BAUD_RATE; 
    localparam CNT_WIDTH = $clog2(SAMPLE_TIME);      

    //STATE DEFINE
    localparam IDLE = 0;
    localparam START = 1;
    localparam DATA0 = 2;
    localparam DATA1 = 3;
    localparam DATA2 = 4;
    localparam DATA3 = 5;
    localparam DATA4 = 6;
    localparam DATA5 = 7;
    localparam DATA6 = 8;
    localparam DATA7 = 9;
    //localparam STOP = 10;

    reg [CNT_WIDTH-1 : 0] clk_cnt;  //clock counter for generating tick
    reg [3:0] c_state, n_state;
    reg [7:0] uart_buffer;
    reg s_out;

    wire busy;
    wire symbol_edge;

    assign busy = (c_state != IDLE) ? 1'b1 : 1'b0;
    assign symbol_edge = (clk_cnt == (SAMPLE_TIME-1)) ? 1'b1 : 1'b0;
    assign serial_out = s_out;
    assign tx_ready = !busy;


    //data buffer
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)              uart_buffer <= 8'h0;
        else if(uart_in_valid)  uart_buffer <= uart_in;
        else if(!busy)          uart_buffer <= 8'h0;
        else                    uart_buffer <= uart_buffer;
    end

    //clock counter
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)              clk_cnt <= 0;
        else if(symbol_edge)    clk_cnt <= 0;
        else                    clk_cnt <= clk_cnt + 1;
    end

    //current state assigner
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)  c_state <= IDLE;
        else        c_state <= n_state;
    end

    //next state assigner
    always @(*)begin
        case(c_state)
            IDLE:   n_state = (uart_in_valid) ? START : c_state;
            START:  n_state = (symbol_edge) ? DATA0 : c_state;
            DATA0:  n_state = (symbol_edge) ? DATA1 : c_state;
            DATA1:  n_state = (symbol_edge) ? DATA2 : c_state;
            DATA2:  n_state = (symbol_edge) ? DATA3 : c_state;
            DATA3:  n_state = (symbol_edge) ? DATA4 : c_state;
            DATA4:  n_state = (symbol_edge) ? DATA5 : c_state;
            DATA5:  n_state = (symbol_edge) ? DATA6 : c_state;
            DATA6:  n_state = (symbol_edge) ? DATA7 : c_state;
            DATA7:  n_state = (symbol_edge) ? IDLE : c_state;
            default: n_state = IDLE;
        endcase
    end

    //state output assignment
    always @(*) begin
        case(c_state)
            IDLE:   s_out = 1'b1;
            START:  s_out = 1'b0;
            DATA0:  s_out = uart_buffer[0];
            DATA1:  s_out = uart_buffer[1];
            DATA2:  s_out = uart_buffer[2];
            DATA3:  s_out = uart_buffer[3];
            DATA4:  s_out = uart_buffer[4];
            DATA5:  s_out = uart_buffer[5];
            DATA6:  s_out = uart_buffer[6];
            DATA7:  s_out = uart_buffer[7];
            default: s_out = 1'b1;
        endcase
    end
endmodule