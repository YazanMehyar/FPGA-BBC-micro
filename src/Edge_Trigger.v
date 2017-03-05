`include "TOP.vh"

module Edge_Trigger (
	input clk,
	input IN,

	output reg EDGE);

	// TYPE defines wether the module reacts to a positive edge or a negative one
	// 1 -> +ve, o/w negative

	parameter TYPE = 1;

	reg prev_IN;

	always_comb
		if(TYPE == 1) EDGE = ~prev_IN & IN;
		else		  EDGE = prev_IN & ~IN;

	always @ (posedge clk) prev_IN <= IN;

endmodule // Edge_Trigger
