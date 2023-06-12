module testbench();
    localparam CLK_FREQ = 50_000_000;
    localparam CLK_PERIOD = 20;
    localparam BAUD_RATE = 9600;
    localparam BAUD_TIME = 1_000_000_000 / BAUD_RATE;

    //connection signal declaration
    reg clk;
    reg n_rst;

    reg [7:0] uart_in;
    reg uart_in_valid;
    wire tx_ready;

    wire serial_out;

    //UUT instance
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    )uut_uart_tx(
        .clk (clk),
        .n_rst (n_rst),

        .uart_in (uart_in),
        .uart_in_valid (uart_in_valid),
        .tx_ready (tx_ready),
        
        .serial_out (serial_out)
    );

    //uart task
    task uart_tx_task;
        input [7:0] data;
    begin
        $display("EXPECT TO SEE: %x", data);
        
        uart_in_valid = 1'b1;
        uart_in = data;
        @(posedge clk);

        uart_in_valid = 1'b0;
    end
    endtask

    integer i;
    task check;
        input [7:0] data;
        reg [9:0] check_buffer;
    begin
        @(posedge clk);
        for(i = 0; i < 10; i = i + 1)begin
            check_buffer[i] = serial_out;
            #(BAUD_TIME);
        end

        $display("HOST RECEIVED: %x",check_buffer[8:1]);

        if(data == check_buffer[8:1])
            $display("***[ PASSED ]***\n\n");
        else begin
            $display("!!![ FAILED ]!!!\n\n");
            $stop;
        end
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
                uart_tx_task(ans);
                check(ans);
            join
        end

        $display("ALL TEST PASSED!");
        $stop;
    end
endmodule