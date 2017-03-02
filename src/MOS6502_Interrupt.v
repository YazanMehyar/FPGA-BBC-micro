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
	wire NMI_edge;
	reg  nNMI_hold;
	Edge_Trigger #(0) NMI_TRIGGER (.clk(clk),.IN(nNMI),.EDGE(NMI_edge));
	
	always @ (posedge clk)
		if(~nRESET)			nNMI_hold <= `NMI_INACTIVE;
		else if(nNMI_hold)	nNMI_hold <= ~NMI_edge;
		else if(clk_en)
			if(T0&~NEXT_T)	nNMI_hold <= ~NMI_edge;
	
	always @ (posedge clk)
		if(~nRESET)			nNMI_T0   <= `NMI_INACTIVE;
		else if(clk_en)
			if(T0&~NEXT_T)	nNMI_T0   <= nNMI_hold;

	always @ (posedge clk)
		if(~nRESET)			nNMI_req  <= `NMI_INACTIVE;
		else if(clk_en)
			if(T0)			nNMI_req  <= nNMI_T0;

/************************************************************************************/
	wire SO_edge;
	reg  SO_hold;
	Edge_Trigger #(0) SO_TRIGGER (.clk(clk),.IN(nSO),.EDGE(SO_edge));
	
	always @ (posedge clk)
		if(~nRESET)			SO_hold <= `SO_INACTIVE;
		else if(~SO_hold)	SO_hold <= SO_edge;
		else if(clk_en)
			if(T0&~NEXT_T)	SO_hold <= SO_edge;

	always @ (posedge clk)
		if(~nRESET)			SO_req <= `SO_INACTIVE;
		else if(clk_en)
			if(T0&~NEXT_T)	SO_req <= SO_hold;

endmodule
