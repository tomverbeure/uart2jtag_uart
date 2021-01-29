
module top(input wire clk50, output wire tx_serial, input wire rx_serial);

    reg reset_ = 0;

    always @(posedge clk50) begin
        reset_ <= 1'b1;
    end

    uart2intel_jtag_uart #(.BAUD(115200), .MAIN_CLK(50000000)) u_uart2intel_jtag_uart(
        .clk(clk50),
        .reset_(reset_),
        .jtag2tx_serial(tx_serial),
        .rx_serial2jtag(rx_serial)
    );

endmodule
