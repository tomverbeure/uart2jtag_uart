`default_nettype none

module uart2intel_jtag_uart
    #(
        parameter BAUD              = 115200,
        parameter MAIN_CLK          = 50000000
    ) (
        input wire      clk,
        input wire      reset_,
        output wire     jtag2tx_serial,
        input wire      rx_serial2jtag
    );

    reg             avbus_chipselect;
    reg             avbus_address;
    reg             avbus_read_n;
    wire [31:0]     avbus_readdata;
    reg             avbus_write_n;
    reg  [31:0]     avbus_writedata;
    wire            avbus_waitrequest;

    jtag_uart u_jtag_uart (
        .clk_clk           (clk),
        .reset_reset_n     (reset_),
        .avbus_chipselect  (avbus_chipselect),
        .avbus_address     (avbus_address),
        .avbus_read_n      (avbus_read_n), 
        .avbus_readdata    (avbus_readdata),
        .avbus_write_n     (avbus_write_n), 
        .avbus_writedata   (avbus_writedata), 
        .avbus_waitrequest (avbus_waitrequest)
    );

    reg         tx_req;
    wire        tx_ready;
    reg  [7:0]  tx_data;

    uart_tx #(.BAUD(BAUD), .MAIN_CLK(MAIN_CLK)) u_uart_tx(
        .clk(clk),
        .reset_(reset_),
        .tx_req(tx_req), 
        .tx_ready(tx_ready),
        .tx_data(tx_data),
        .uart_tx(jtag2tx_serial)
    );

    wire        rx_req;
    reg         rx_ready;
    wire [7:0]  rx_data;

    uart_rx #(.BAUD(BAUD), .MAIN_CLK(MAIN_CLK)) u_uart_rx(
        .clk(clk),
        .reset_(reset_),
        .rx_req(rx_req),
        .rx_ready(rx_ready),
        .rx_data(rx_data),
        .uart_rx(rx_serial2jtag)
    );

    localparam JTAG_UART_DATA_ADDR          = 0;
    localparam JTAG_UART_CTRL_ADDR          = 1;

    localparam FSM_IDLE                     = 2'h0;
    localparam FSM_CHECK_DATA_FROM_JTAG     = 2'h1;
    localparam FSM_CHECK_DATA_TO_JTAG       = 2'h2;
    localparam FSM_WRITE_DATA_TO_JTAG       = 2'h3;

    reg [1:0] cur_state, nxt_state;

    always @* begin
        nxt_state       = cur_state;

        avbus_chipselect    = 1'b0;
        avbus_address       = 1'b0;
        avbus_read_n        = 1'b1;
        avbus_write_n       = 1'b1;
        avbus_writedata     = { 24'd0, rx_data };

        tx_req          = 1'b0;
        tx_data         = avbus_readdata[7:0];

        rx_ready        = 1'b0;

        case(cur_state)
            FSM_IDLE: begin

                if (tx_ready) begin
                    nxt_state       = FSM_CHECK_DATA_FROM_JTAG;
                end
                else if (rx_req) begin
                    nxt_state       = FSM_CHECK_DATA_TO_JTAG;
                end

            end
            FSM_CHECK_DATA_FROM_JTAG: begin
                avbus_chipselect        = 1'b1;
                avbus_read_n            = 1'b0;
                avbus_address           = JTAG_UART_DATA_ADDR;

                if (!avbus_waitrequest) begin
                    if (avbus_readdata[15]) begin          // RVALID
                        // tx_ready was checked to be asserted before
                        // entering this state, so we know for sure that
                        // tx_req will be accepted right away.
                        tx_req              = 1'b1;
                        nxt_state           = FSM_IDLE;
                    end
                    else begin
                        nxt_state           = FSM_IDLE;
                    end
                end
            end
            FSM_CHECK_DATA_TO_JTAG: begin
                avbus_chipselect        = 1'b1;
                avbus_read_n            = 1'b0;
                avbus_address           = JTAG_UART_CTRL_ADDR;

                if (!avbus_waitrequest) begin
                    if (avbus_readdata[31:16] != 0) begin   // WSPACE != 0
                        nxt_state       = FSM_WRITE_DATA_TO_JTAG;
                    end
                end
            end
            FSM_WRITE_DATA_TO_JTAG: begin
                avbus_chipselect        = 1'b1;
                avbus_write_n           = 1'b0;
                avbus_address           = JTAG_UART_DATA_ADDR;
                avbus_writedata         = { 24'd0, rx_data };

                if (!avbus_waitrequest) begin
                    nxt_state           = FSM_IDLE;
                    rx_ready            = 1'b1;
                end
            end

        endcase
    end

    always @(posedge clk or negedge reset_) begin
        if (!reset_) begin
            cur_state       <= FSM_IDLE;
        end
        else begin
            cur_state       <= nxt_state;
        end
    end

endmodule

