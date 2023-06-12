//Intel DE0
//UART Echo-Back Test
module top(
    input clk,
    input n_rst,

    input RxD,
    output TxD
);
    localparam CLK_FREQ = 50_000_000;
    localparam BAUD_RATE = 9600;
    wire [7:0] uart_in;
    wire uart_in_valid;

    //RS-232 to CP210x Converting
    wire inv_TxD;
    assign TxD = ~inv_TxD;

    uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    )u_uart(
    .clk (clk),
    .n_rst (n_rst),

    .uart_in (uart_in),
    .uart_in_valid (uart_in_valid),
    .rx_ready (),

    .uart_out (uart_in),
    .uart_out_valid (uart_in_valid),
    .tx_ready (),

    .RxD(~RxD), //CP210x to RS-232 Converting
    .TxD(inv_TxD)
);
endmodule