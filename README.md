# verilog_uart_module
> ### Variable baudrate support uart module
## Specs
|Object|Number|  
|:--:|:--:|  
|CLOCK FREQ| 50MHz or Above|  
|BAUD RATE| Variable (2400 ~ 250K)|  
|CONNECTOR TYPE| RS-232 or CP210x|  
|INPUT BUFFER SIZE|8 Bit|      
|STOP BIT|1 Bit|  
|PARITY BIT|NO|     

## Design Hierarchy
> - ## uart (top)
>   - ### uart_rx (sub module)
>   - ### uart_tx (sub module)
## Module Behavior

- ### UART_RX

