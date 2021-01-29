
module uart_rx (
    input                   clk, 
    input                   reset_, 
    output reg              rx_req,
    input                   rx_ready,
    output reg [7:0]        rx_data,
    output reg              rx_error,
    input                   uart_rx
    );

    parameter MAIN_CLK    = 100000000;
    parameter BAUD         = 115200;

    localparam BAUD_DIVIDE     = MAIN_CLK/BAUD;

    wire     uart_rx_sync;

    sync_dd_c u_sync_uart_rx(
        .clk(clk),
        .reset_(reset_), 
        .sync_in(uart_rx), 
        .sync_out(uart_rx_sync)
    );

    reg [$clog2(BAUD_DIVIDE)-1:0] baud_cntr;

    reg [3:0]       bit_cntr;
    reg [7:0]       rx_shift_reg;
    reg             rx_active;
    reg             uart_rx_sync_p1;

    always @(posedge clk or negedge reset_) 
    begin
        if (!reset_) begin
            rx_active   <= 1'b0;
            rx_req      <= 1'b0;
            rx_error    <= 1'b0;
        end
        else begin
            if (rx_ready) begin
                rx_req      <= 1'b0;
                rx_error    <= 1'b0;
            end

            if (!rx_active) begin
                if (!uart_rx_sync && uart_rx_sync_p1) begin
                    // Falling edge -> START bit
                    rx_active       <= 1'b1;
                    bit_cntr        <= 0;
    
                    // Sample the START bit in the middle
                    baud_cntr       <= BAUD_DIVIDE/2;
                end
            end
            else if (baud_cntr != 0) begin
                baud_cntr           <= baud_cntr - 4'd1;
            end
            else if (bit_cntr == 0) begin
                if (uart_rx_sync) begin
                    // This is still the START bit. 
                    // If it's not 0, then something is wrong, so go back to 
                    // looking for a start of transaction.
                    rx_active       <= 1'b0;
                end
                else begin
                    baud_cntr       <= BAUD_DIVIDE;
                    bit_cntr        <= bit_cntr + 4'd1;
                end
            end
            else if (bit_cntr <= 4'd8) begin
                rx_shift_reg[7:0]   <= { uart_rx_sync, rx_shift_reg[7:1] };
    
                baud_cntr           <= BAUD_DIVIDE;
                bit_cntr            <= bit_cntr + 4'd1;
            end
            else if (!uart_rx_sync) begin
                // This is the STOP bit of the transaction, so it should be a 1.
                // But it's not. 
                // Raise an error, but still send out the output.
                rx_req              <= 1'b1;
                rx_data             <= rx_shift_reg;
                rx_error            <= 1'b1;
    
                rx_active           <= 1'b0;
    
`ifndef SYNTHESIS
                $display("%m: Receive error! ('%c')", rx_shift_reg);
`endif
            end
            else begin
                rx_req              <= 1'b1;
                rx_data             <= rx_shift_reg;
    
                rx_active           <= 1'b0;
    
`ifndef SYNTHESIS
                $display("%m: Character received '%c'", rx_shift_reg);
`endif
            end
    
            uart_rx_sync_p1    <= uart_rx_sync;
        end
    end

endmodule
