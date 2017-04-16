`include "MOS6502.vh"

module MOS6502_Interrupt (
	input clk,
	input clk_en,
	input nNMI,
	input nIRQ,
	input nSO,
	input nRESET,
	input NEXT_T,
	input I_mask,

	output reg nNMI_req,
	output reg nIRQ_req,
	output reg SO_req);

/************************************************************************************/

	always @ (posedge clk)
		if(~nRESET) 	nIRQ_req <= 1'b1;
		else if(clk_en)
			if(NEXT_T)	nIRQ_req <= nIRQ | I_mask;

/************************************************************************************/

	reg T0SINGLE;
	always @ (posedge clk)
		if(clk_en) T0SINGLE <= NEXT_T;

	wire NEXT_T0 = ~T0SINGLE & NEXT_T;
	wire EDGE_en = clk_en&NEXT_T0|~nRESET;

	wire NMI_edge;
	Edge_Trigger #(0) NMI_TRIGGER (.clk(clk),.IN(nNMI),.En(EDGE_en),.EDGE(NMI_edge));

	always @ (posedge clk)
		if(~nRESET) 	nNMI_req  <= 1'b1;
		else if(clk_en)
			if(NEXT_T0)	nNMI_req  <= ~NMI_edge;


	wire SO_edge;
	Edge_Trigger #(0) SO_TRIGGER (.clk(clk),.IN(nSO),.En(EDGE_en),.EDGE(SO_edge));

	always @ (posedge clk)
		if(~nRESET) 	SO_req <= 1'b0;
		else if(clk_en)
			if(NEXT_T0)	SO_req <= SO_edge;

endmodule
