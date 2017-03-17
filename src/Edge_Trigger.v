`include "TOP.vh"

module Edge_Trigger (
	input clk,
	input IN,
	input En,

	output reg EDGE);

	// TYPE defines wether the module reacts to a positive edge or a negative edge
	// 1 -> +ve, o/w negative

	parameter TYPE = 1;

	reg prev_IN;
	reg prev_IN2;
	reg wEDGE;

	always @ (*)
		if(TYPE == 1) wEDGE = prev_IN  & ~prev_IN2;
		else		  wEDGE = ~prev_IN &  prev_IN2;

	always @ (posedge clk) prev_IN <= IN;
	always @ (posedge clk) prev_IN2<= prev_IN;
	
	always @ (posedge clk)
		if(~EDGE|En) EDGE <= wEDGE;

endmodule // Edge_Trigger
