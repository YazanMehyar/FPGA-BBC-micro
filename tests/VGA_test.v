`timescale 1ns/1ns

module VGA_test ();

	`define CLKPERIOD 10

	reg CLK100MHZ;
	initial begin
		$dumpvars(0,VGA_test);
		CLK100MHZ = 0;

		forever #(`CLKPERIOD/2) CLK100MHZ = ~CLK100MHZ;
	end

	// input
	reg nRESET;

	// output
	wire HS;
	wire VS;

	VGA vga(
		.CLK100MHZ(CLK100MHZ),
		.nRESET(nRESET),
		.VGA_HSYNC(HS),
		.VGA_VSYNC(VS));

	initial begin
		nRESET <= 0;
		repeat (10) @(posedge CLK100MHZ);

		nRESET <= 1;
		repeat (10) @(posedge VS);
		$finish;
	end

endmodule // VGA_test
