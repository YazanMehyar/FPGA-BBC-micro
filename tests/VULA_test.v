module VULA_test();

	initial $dumpvars(0, VULA_test);
	
	reg clk16MHz,
	reg nRESET,
	reg A0,
	reg nCS,
	reg DISEN,
	reg CURSOR,
	reg [7:0] DATA,

	output clk8MHz,
	output clk4MHz,
	output clk2MHz,
	output clk1MHz,
	output clkCRTC,
	output REDout,
	output GREENout,
	output BLUEout);
