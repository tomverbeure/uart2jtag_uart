
module uart_tx
    (
    input           clk, 
    input           reset_, 
    input           tx_req,
    output          tx_ready,
    input [7:0]     tx_data,
    output reg      uart_tx
    );

    parameter MAIN_CLK      = 100000000;
    parameter BAUD          = 115200;

    localparam BAUD_DIVIDE  = MAIN_CLK/BAUD;

    reg [$clog2(BAUD_DIVIDE)-1:0]    baud_cntr;
    reg         baud_tick;

    always @(posedge clk or negedge reset_) begin

        if (!reset_) begin
            baud_cntr     <= 4'd0;
            baud_tick     <= 1'b0;
        end
        else begin
            baud_tick     <= 1'b0;

            if (baud_cntr == 4'd0) begin
                baud_cntr     <= BAUD_DIVIDE-1;
                baud_tick     <= 1'b1;
            end
            else begin
                baud_cntr     <= baud_cntr - 1'd1;
            end
        end
    end

    reg [3:0]   tx_bit_cntr;
    reg [9:0]   tx_shift_reg;

    always @(posedge clk or negedge reset_) begin

        if (!reset_) begin
            tx_bit_cntr     <= 0;
            uart_tx         <= 1'b1;
        end
        else begin
            if (tx_req && tx_bit_cntr == 0) begin
`ifndef SYNTHESIS
                $display("%m: Send Character '%c'", tx_data);
`endif
                tx_shift_reg        <= { 1'b1, tx_data, 1'b0 };
                tx_bit_cntr         <= 4'd10;
            end

            if (baud_tick && tx_bit_cntr != 0) begin
                uart_tx         <= tx_shift_reg[0];
                tx_shift_reg    <= { 1'b0, tx_shift_reg[9:1] };
                tx_bit_cntr     <= tx_bit_cntr - 1'd1;
            end

        end
    end

    assign tx_ready     = (tx_bit_cntr == 4'd0);

endmodule
