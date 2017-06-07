`include "TOP.vh"

module PS2Driver_test();

	// input
	reg CLK;
	reg nRESET;
	reg PS2_DATA;
	wire PS2_CLK;
	wire CLK_en;
	
	// output
	wire [7:0] DATA;
	wire DONE;

	
	PS2_DRIVER ps2(
	.CLK(CLK),
	.CLK_en(CLK_en),
	.nRESET(nRESET),
	.PS2_CLK(PS2_CLK),
	.PS2_DATA(PS2_DATA),
	
	.DATA(DATA),
	.DONE(DONE));
	
	initial $dumpvars(0, PS2Driver_test);
	
	// Timing
	initial CLK = 0;
	always #(`CLKPERIOD/2) CLK = ~CLK;
	
	reg [6:0] CLKCOUNTER = 0;
	
	always @(posedge CLK) CLKCOUNTER <= CLKCOUNTER + 1;
	assign CLK_en  = &CLKCOUNTER[2:0];
	assign PS2_CLK = ~CLKCOUNTER[6];
	
	// Test
	initial begin
		nRESET <= 0;
		PS2_DATA<= 1'b1;
		repeat (5) @(posedge CLK);
	
		nRESET <= 1;
		repeat (5) @(posedge CLK);
	
		repeat (33)
			@(posedge PS2_CLK)
			PS2_DATA <= $urandom_range(9,8);
	
		repeat (5) @(posedge CLK);
		$finish;
	end
	
endmodule
	
	
