module testbench();
    reg clk;
    reg n_rst;

    reg uart_in_valid;
    reg [7:0] uart_in;

    wire serial_out;
    wire tx_ready;

    parameter TB_CLOCK_FREQ = 50_000_000;
    parameter TB_BAUD_RATE = 115_200;

    localparam CLK_PERIOD = 1_000_000_000 / TB_CLOCK_FREQ;
    localparam BAUD_PERIOD = 1_000_000_000 / TB_BAUD_RATE;

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

    uart_tx #(
        .CLOCK_FREQ(TB_CLOCK_FREQ),
        .BAUD_RATE(TB_BAUD_RATE)
    )dut_uart_tx(
        .clk(clk),
        .n_rst(n_rst),
        .uart_in_valid(uart_in_valid),
        .uart_in(uart_in),

        .serial_out(serial_out),
        .tx_ready(tx_ready)
    );

    integer i;
    integer state;
    task msg_generator;
        input [7:0] message;
        reg [7:0] data;
        begin
            @(posedge clk);
            uart_in_valid = 1'b1;
            uart_in = message;
            
            @(posedge clk);
            uart_in_valid = 1'b0;
            uart_in = 8'h0;

            wait(dut_uart_tx.symbol_edge);

            for(i = 0; i < 10; i = i + 1)begin
                state = dut_uart_tx.c_state;

                if(state == DATA0)
                    data[0] = serial_out;
                if(state == DATA1)
                    data[1] = serial_out;
                if(state == DATA2)
                    data[2] = serial_out;
                if(state == DATA3)
                    data[3] = serial_out;
                if(state == DATA4)
                    data[4] = serial_out;
                if(state == DATA5)
                    data[5] = serial_out;
                if(state == DATA6)
                    data[6] = serial_out;
                if(state == DATA7)
                    data[7] = serial_out;
                
                #(BAUD_PERIOD);
            end

            wait(tx_ready);

            $display("==TESTCOUNT %3d==", (k + 1));
            $display("TX( FPGA >>> ): %x", message);
            $display("RX( HOST <<< ): %x", data);

            if(message == data) begin
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
        #7 n_rst = 1;
    end

    integer k;
    initial begin
        uart_in_valid = 0;
        wait(n_rst);
        for(k = 0; k < 1000; k = k + 1)begin
            msg_generator($random()%256); // 00 ~ FF
        end

        repeat(BAUD_PERIOD) @(posedge clk);
        $stop;
    end
endmodule