/**
* @Author: Yazan Mehyar <zen>
* @Date:   25-Dec-2016
* @Email:  stcyazanerror@gmail.com
* @Filename: Interrupt_6502.v
* @Last modified by:   zen
* @Last modified time: 29-Dec-2016
*/

module Interrupt_6502 (
	input clk,
	input NMI_pin,
	input IRQ_pin,
	input SO_pin,
	input RESET_pin,
	input T0,
	input NEXT_T,
	input I_mask,

	output reg NMI_req,
	output NMI_T0,
	output reg IRQ_req,
	output IRQ_T0,
	output SO_req);

/************************************************************************************/
	wire IRQ_out;

	Level_Trigger IRQ(
		.clk(clk),
		.LEVEL_pin(IRQ_pin),
		.RESET_pin(RESET_pin),
		.T0(T0),
		.LEVEL(IRQ_out)
		);

	assign IRQ_T0 = IRQ_out | I_mask;

	always @ (posedge clk)
		if(~RESET_pin) // active low reset
			IRQ_req <= 1'b1;
		else if(T0)
			IRQ_req <= IRQ_T0;

/************************************************************************************/
	Edge_Trigger NMI(
		.clk(clk),
		.EDGE_pin(NMI_pin),
		.RESET_pin(RESET_pin),
		.T0(T0),
		.NEXT_T(NEXT_T),
		.EDGE(NMI_T0)
		);

	always @ (posedge clk)
		if(~RESET_pin)
			NMI_req <= 1'b1;
		else if(T0)
			NMI_req <= NMI_T0;

/************************************************************************************/
	wire SO_out;

	assign SO_req = ~SO_out;
	Edge_Trigger SO(
		.clk(clk),
		.EDGE_pin(SO_pin),
		.RESET_pin(RESET_pin),
		.T0(T0),
		.NEXT_T(NEXT_T),
		.EDGE(SO_out)
		);

endmodule // Interrupt_6502
