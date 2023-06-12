module testbench();
    localparam CLK_FREQ = 50_000_000;
    localparam CLK_PERIOD = 20;
    localparam BAUD_RATE = 9600;
    localparam BAUD_TIME = 1_000_000_000 / BAUD_RATE;

    //connection signal declaration
    reg clk;
    reg n_rst;

    wire [7:0] uart_out;
    wire uart_out_valid;
    wire rx_ready;

    reg serial_in;

    //UUT instance
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    )uut_uart_rx(
        .clk (clk),
        .n_rst (n_rst),

        .uart_out (uart_out),
        .uart_out_valid (uart_out_valid),
        .rx_ready (rx_ready),

        .serial_in (serial_in)
    );

    //uart task
    integer i;
    task uart_rx_task;
        input [7:0] data;
    begin
        $display("EXPECT TO SEE: %X",data);
        serial_in = 1'b0;
        #(BAUD_TIME);

        for(i = 0; i < 8; i = i + 1)begin
            serial_in = data[i];
            #(BAUD_TIME);
        end

        serial_in = 1'b1;
        #(BAUD_TIME);
    end
    endtask

    //verifying task
    task check;
        input [7:0] data;
    begin
        while(!uart_out_valid) begin
            @(posedge clk);
        end

        $display("FPGA RECEIVED: %X",uart_out);
        if(data == uart_out)
            $display("***[ PASSED ]***\n\n");
        else begin
            $display("!!![ FAILED ]!!!\n\n");
            $stop;
        end

        repeat(100) @(posedge clk);
    end
    endtask
        
    

    //clock & reset initiallize
    initial begin
        clk = 1'b0;
        n_rst = 1'b0;
        #7 n_rst = 1'b1;
    end

    //clock generation
    always #(CLK_PERIOD/2) clk = ~clk;    

    //testvector
    integer k;
    integer ans;
    initial begin
        wait(n_rst);
        @(posedge clk);
        for(k = 1; k <= 100; k = k + 1)begin
            $display("TESTCOUNT: %3d",k);
            $display("------------------");
            ans = $urandom()%8'hFF;
            fork
                uart_rx_task(ans);
                check(ans);
            join
        end

        $display("ALL TEST PASSED!");
        $stop;
    end
endmodule