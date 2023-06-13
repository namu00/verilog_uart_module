module uart_rx#(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input clk,
    input n_rst,

    output [7:0] uart_out,
    output uart_out_valid,
    output rx_ready,

    input serial_in
);

    localparam TIME_EDGE = CLK_FREQ / BAUD_RATE;
    localparam CNT_WIDTH = $clog2(TIME_EDGE);
    localparam READ_TIME = TIME_EDGE / 2;

    //internal registers
    reg busy;
    reg [CNT_WIDTH-1:0] clk_cnt;
    reg [3:0] buff_cnt;
    reg [9:0] buffer;

    //internal flags
    wire symbol_edge;
    wire cnt_reset;
    wire start;
    wire read;
    wire eob;

    //flag assignment

    //rx start
    assign start = (!serial_in) && (!busy);

    //uart BPS tick
    assign symbol_edge = (clk_cnt == (TIME_EDGE-1)) ? 1'b1 : 1'b0;

    //clock counter reset flag
    assign cnt_reset = (!busy) || (start) || (symbol_edge);

    //uart input read flag (read time)
    assign read = (clk_cnt == READ_TIME) ? 1'b1 : 1'b0;

    //end of buffer
    assign eob = (buff_cnt == 4'hA) ? 1'b1 : 1'b0;

    //output assignment
    assign uart_out = buffer[8:1];
    assign uart_out_valid = eob;
    assign rx_ready = !busy;

    //busy control
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            busy <= 1'b0;
        else if(start)
            busy <= 1'b1;
        else if(eob)
            busy <= 1'b0;
        else
            busy <= busy;
    end

    //clock counter for generating symbol_edge
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            clk_cnt <= 0;
        else if(cnt_reset)
            clk_cnt <= 0;
        else
            clk_cnt <= clk_cnt + 1;
    end

    //uart byte buffer
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            buffer <= 10'h3FF;
        else if(start)
            buffer <= 10'h3FF;
        else if(read)
            buffer <= {serial_in,buffer[9:1]};
        else
            buffer <=  buffer;
    end

    //buffer bit counter
    always @(posedge clk or negedge n_rst)begin
        if(!n_rst)
            buff_cnt <= 4'h0;
        else if(!busy)
            buff_cnt <= 4'h0;
        else if(symbol_edge)
            buff_cnt <= buff_cnt + 4'h1;
        else
            buff_cnt <= buff_cnt;
    end
endmodule