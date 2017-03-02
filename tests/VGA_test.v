`timescale 1ns/1ns

module VGA_test ();

	`define CLKPERIOD 10

	reg PIXELCLK;
	initial begin
		$dumpvars(0,VGA_test);
		PIXELCLK = 0;

		forever #(`CLKPERIOD/2) PIXELCLK = ~PIXELCLK;
	end

	// input
	reg nRESET;

	// output
	wire HS;
	wire VS;
	wire ENDofLINE;
	wire NEWSCREEN;
	wire DISEN;

	VGA vga(
		.PIXELCLK(PIXELCLK),
		.nRESET(nRESET),
		.VGA_HS(HS),
		.VGA_VS(VS),
		.ENDofLINE(ENDofLINE),
		.NEWSCREEN(NEWSCREEN),
		.DISEN(DISEN));

	initial begin
		nRESET <= 0;
		repeat (10) @(posedge PIXELCLK);

		nRESET <= 1;
		repeat (10) @(posedge VS);
		$finish;
	end

endmodule // VGA_test
