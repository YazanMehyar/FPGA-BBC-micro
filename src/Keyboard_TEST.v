module Keyboard_TEST(
	input CLK100MHZ,
	input PS2_CLK,
	input PS2_DATA,
	input CPU_RESETN,
	
	output [15:0] LED);
	
	reg [1:0] CLKEN;
	always @ ( posedge CLK100MHZ ) CLKEN <= CLKEN + 1;
	
	wire DONE;
	reg [7:0] DONE_Q;
	always @ ( posedge CLK100MHZ )
		if(~CPU_RESETN)
			DONE_Q <= 8'h1;
		else if(CLKEN&DONE)
			DONE_Q <= {DONE_Q[6:0],DONE_Q[7]};
	
	assign LED[15:8] = DONE_Q;
	
	PS2_DRIVER ps2(
		.clk(CLK100MHZ),
		.clk_en(CLKEN[1]),
		.nRESET(CPU_RESETN),
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		.DATA(LED[7:0]),
		.DONE(DONE)
		);
endmodule
