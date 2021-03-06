// jtag_uart.v

// Generated using ACDS version 20.1 720

`timescale 1 ps / 1 ps
module jtag_uart (
		input  wire        avbus_chipselect,  // avbus.chipselect
		input  wire        avbus_address,     //      .address
		input  wire        avbus_read_n,      //      .read_n
		output wire [31:0] avbus_readdata,    //      .readdata
		input  wire        avbus_write_n,     //      .write_n
		input  wire [31:0] avbus_writedata,   //      .writedata
		output wire        avbus_waitrequest, //      .waitrequest
		input  wire        clk_clk,           //   clk.clk
		input  wire        reset_reset_n      // reset.reset_n
	);

	jtag_uart_u_jtag_uart u_jtag_uart (
		.clk            (clk_clk),           //               clk.clk
		.rst_n          (reset_reset_n),     //             reset.reset_n
		.av_chipselect  (avbus_chipselect),  // avalon_jtag_slave.chipselect
		.av_address     (avbus_address),     //                  .address
		.av_read_n      (avbus_read_n),      //                  .read_n
		.av_readdata    (avbus_readdata),    //                  .readdata
		.av_write_n     (avbus_write_n),     //                  .write_n
		.av_writedata   (avbus_writedata),   //                  .writedata
		.av_waitrequest (avbus_waitrequest), //                  .waitrequest
		.av_irq         ()                   //               irq.irq
	);

endmodule
