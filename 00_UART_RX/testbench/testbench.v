module testbench();
    reg clk;
    reg n_rst;
    reg serial_in;

    wire [7:0] uart_out;
    wire uart_out_valid;

    parameter TB_CLOCK_FREQ = 50_000_000;
    parameter TB_BAUD_RATE = 115_200;

    localparam CLK_PERIOD = 1_000_000_000 / TB_CLOCK_FREQ;
    localparam BAUD_PERIOD = 1_000_000_000 / TB_BAUD_RATE;

    uart_rx #(
        .CLOCK_FREQ(TB_CLOCK_FREQ),
        .BAUD_RATE(TB_BAUD_RATE)
    )dut_uart_rx(
        .clk(clk),
        .n_rst(n_rst),
        .serial_in(serial_in),
        .uart_out(uart_out),
        .uart_out_valid(uart_out_valid)
    );

    integer i;
    task msg_generator;
        input [7:0] message;
        begin
            serial_in = 0;
            #(BAUD_PERIOD);

            for(i = 0; i < 8; i = i + 1)begin
                serial_in = message[i];
                #(BAUD_PERIOD);
            end

            serial_in = 1;
            #(BAUD_PERIOD);

            wait(uart_out_valid);

            $display("==TESTCOUNT %3d==", (k + 1));
            $display("TX( HOST >>> ): %x", message);
            $display("RX( FPGA <<< ): %x", uart_out);

            if(message == uart_out) begin
                $display("    [PASSED]\n\n");
            end
            else begin
                $display("    [FAILED]\n\n");
                $stop;
            end 
        end
    endtask

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        n_rst = 0;
        #10 n_rst = 1;
    end

    integer k;
    initial begin
        serial_in = 1;
        wait(n_rst);
        for(k = 0; k < 1000; k = k + 1)begin
            serial_in = 1;
            msg_generator($random()%256); // 00 ~ FF
            serial_in = 1;
        end

        repeat(BAUD_PERIOD) @(posedge clk);
        $stop;
    end
endmodule