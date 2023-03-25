/*
    Writer: namu00
    Github: https://github.com/namu00/verilog_uart_module

    Target Clock: 50Mhz
    Module Description: UART RX module
*/

module uart_rx#(
    parameter CLOCK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input clk,
    input n_rst,
    input serial_in,

    output [7:0] uart_out,
    output uart_out_valid
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
    localparam STOP = 10;

    reg [CNT_WIDTH-1 : 0] clk_cnt;  //clock counter for generating tick
    reg [7:0] uart_buffer;          //UART byte buffer
    reg valid, valid_d;             //validation edge detecting register

    reg [3:0] c_state, n_state;     //state register

    wire symbol_edge;               //buffer update ticker
    wire busy;                      //busy flag
    wire start, stop;               //start & stop flag

    //flag assigment
    assign start = (!serial_in) && (!busy); 
    assign busy = (c_state != IDLE) ? 1'b1 : 1'b0;
    assign stop = (c_state == STOP) && (busy) ? 1'b1 : 1'b0;
    assign symbol_edge = (clk_cnt == (SAMPLE_TIME-1)) ? 1'b1 : 1'b0;

    //output assignment
    assign uart_out = uart_buffer;
    assign uart_out_valid = (!valid) && (valid_d);


    //clock counter
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)              clk_cnt <= 0;
        else if(symbol_edge)    clk_cnt <= 0;
        else if(busy)           clk_cnt <= clk_cnt + 1;
        else                    clk_cnt <= 0;
    end

    //validation control
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)      valid <= 1'b0;
        else if(stop)   valid <= 1'b1;
        else            valid <= 1'b0;
    end

    //validation edge detecting logic
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)  valid_d <= 1'b0;
        else        valid_d <= valid;
    end

    //current state assigner
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)  c_state <= IDLE;
        else        c_state <= n_state;
    end

    //next state assigner
    always @(*)begin
        case(c_state)
            IDLE:   n_state = (start) ? START : c_state;
            START:  n_state = (symbol_edge) ? DATA0 : c_state;

            DATA0:  n_state = (symbol_edge) ? DATA1 : c_state;
            DATA1:  n_state = (symbol_edge) ? DATA2 : c_state;
            DATA2:  n_state = (symbol_edge) ? DATA3 : c_state;
            DATA3:  n_state = (symbol_edge) ? DATA4 : c_state;
            DATA4:  n_state = (symbol_edge) ? DATA5 : c_state;
            DATA5:  n_state = (symbol_edge) ? DATA6 : c_state;
            DATA6:  n_state = (symbol_edge) ? DATA7 : c_state;
            DATA7:  n_state = (symbol_edge) ? STOP  : c_state;

            STOP:   n_state = (symbol_edge) ? IDLE  : c_state;
            default: n_state = IDLE;
        endcase
    end

    //state behavior assigner
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)      uart_buffer <= 8'h00;
        else if(start)  uart_buffer <= 8'h00;
        else if(symbol_edge) begin
            case(c_state) 
                START: uart_buffer[0] <= serial_in;
                DATA0: uart_buffer[1] <= serial_in;
                DATA1: uart_buffer[2] <= serial_in;
                DATA2: uart_buffer[3] <= serial_in;
                DATA3: uart_buffer[4] <= serial_in;
                DATA4: uart_buffer[5] <= serial_in;
                DATA5: uart_buffer[6] <= serial_in;
                DATA6: uart_buffer[7] <= serial_in;

                default: uart_buffer <= uart_buffer;
            endcase
        end
        else uart_buffer <= uart_buffer;
    end
endmodule