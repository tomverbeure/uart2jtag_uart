
# UART to JTAG_UART

This project links a UART to a JTAG UART. This makes is possible to allow a host PC
to observe what's happening on a regular UART even if the host PC doesn't have a serial
cable to do so.

For example, Intel's [Cyclone 10 LP FPGA Evaluation Kit](https://www.intel.com/content/www/us/en/programmable/products/boards_and_kits/dev-kits/altera/cyclone-10-lp-evaluation-kit.html)
doesn't have serial to USB chips (unlike many of Intel's other board.) If you have
a piece of code that uses the UART as console, either need to wire up some serial
cable contraption (if you have one), or you might have to make chances in the RTL and
replace the UART with JTAG UART.

This might not be easy to do.

The UART to JTAG UART could be a good alternative: instead of replacing the UART internal
to the design of interest, it adds another UART to convert the internal UART traffic
back to and from parallel data, and then read or write that data to the JTAG UART. 

In an Intel FPGA environment, The user can now use a nios2-terminal to connect
to the design inside the FPGA (that still thinks it's dealing with a regular UART.)

