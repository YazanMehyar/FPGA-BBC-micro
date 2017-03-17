`include "MOS6502.vh"

module MOS6502_Interrupt (
	input clk,
	input clk_en,
	input nNMI,
	input nIRQ,
	input nSO,
	input nRESET,
	input T0,
	input NEXT_T,
	input I_mask,

	output reg nNMI_req,
	output reg nNMI_T0,
	output reg nIRQ_req,
	output reg nIRQ_T0,
	output reg SO_req);

/************************************************************************************/

	always @ (posedge clk)
		if(~nRESET) 	nIRQ_T0  <= `IRQ_INACTIVE;
		else if(clk_en)
			if(~T0)		nIRQ_T0  <= nIRQ | I_mask;

	always @ (posedge clk)
		if(~nRESET)		nIRQ_req <= `IRQ_INACTIVE;
		else if(clk_en)
			if(T0)		nIRQ_req <= nIRQ_T0;

/************************************************************************************/

	wire NEXT_T1 = T0 & ~NEXT_T;

	wire NMI_edge;
	Edge_Trigger #(0) NMI_TRIGGER (.clk(clk),.IN(nNMI),.En(clk_en&NEXT_T1),.EDGE(NMI_edge));
	
	always @ (posedge clk)
		if(~nRESET)		nNMI_T0   <= `NMI_INACTIVE;
		else if(clk_en)
			if(NEXT_T1)	nNMI_T0   <= ~NMI_edge;

	always @ (posedge clk)
		if(~nRESET)		nNMI_req  <= `NMI_INACTIVE;
		else if(clk_en)
			if(T0)		nNMI_req  <= nNMI_T0;


	wire SO_edge;
	Edge_Trigger #(0) SO_TRIGGER (.clk(clk),.IN(nSO),.En(clk_en&NEXT_T1),.EDGE(SO_edge));
	
	always @ (posedge clk)
		if(~nRESET)		SO_req <= `SO_INACTIVE;
		else if(clk_en)
			if(NEXT_T1)	SO_req <= SO_edge;

endmodule
