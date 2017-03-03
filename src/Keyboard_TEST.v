module Keyboard_TEST(
	input CLK100MHZ,
	input PS2_CLK,
	input PS2_DATA,
	input CPU_RESETN,
	
	output reg [15:0] LED);
	
	reg [5:0] CLKCOUNT;
	always @ ( posedge CLK100MHZ ) CLKCOUNT <= CLKCOUNT + 1;
    wire CLKEN = &CLKCOUNT;
	
	wire DONE;
	wire [7:0] DATA;
	always @ ( posedge CLK100MHZ )
		if(~CPU_RESETN)
			LED[15:8] <= 8'h1;
		else if(CLKEN&DONE)
			LED[15:8] <= {LED[14:8],LED[15]};
			
	always @ (posedge CLK100MHZ)
	   if(~CPU_RESETN)
	       LED[7:0] <= 8'h00;
	   else if(CLKEN)
	       LED[7:0] <= DATA;
	
	PS2_DRIVER ps2(
		.clk(CLK100MHZ),
		.clk_en(CLKEN),
		.nRESET(CPU_RESETN),
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		.DATA(DATA),
		.DONE(DONE)
		);
endmodule
