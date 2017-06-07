`include "MOS6502.vh"

module MOS6502_Interrupt (
	input CLK,
	input CLK_en,
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

	always @ (posedge CLK)
		if(~nRESET) 	nIRQ_req <= 1'b1;
		else if(CLK_en)
			if(NEXT_T)	nIRQ_req <= nIRQ | I_mask;

/************************************************************************************/

	reg T0SINGLE;
	always @ (posedge CLK)
		if(CLK_en) T0SINGLE <= NEXT_T;

	wire NEXT_T0 = ~T0SINGLE & NEXT_T;
	wire EDGE_en = CLK_en&NEXT_T0|~nRESET;

	wire NMI_edge;
	Edge_Trigger #(0) NMI_TRIGGER (.CLK(CLK),.IN(nNMI),.En(EDGE_en),.EDGE(NMI_edge));

	always @ (posedge CLK)
		if(~nRESET) 	nNMI_req  <= 1'b1;
		else if(CLK_en)
			if(NEXT_T0)	nNMI_req  <= ~NMI_edge;


	wire SO_edge;
	Edge_Trigger #(0) SO_TRIGGER (.CLK(CLK),.IN(nSO),.En(EDGE_en),.EDGE(SO_edge));

	always @ (posedge CLK)
		if(~nRESET) 	SO_req <= 1'b0;
		else if(CLK_en)
			if(NEXT_T0)	SO_req <= SO_edge;

endmodule
