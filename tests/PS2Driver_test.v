module PS2Driver_test();

	// input
	reg CLK;
	reg nRESET;
	reg En;
	reg PS2_CLK;
	reg PS2_DATA;
	
	// output
	wire [7:0] DATA;
	wire DONE;
	
	
	`define CLK_PERIOD 10
	
	PS2_DRIVER ps2(
	.CLK(CLK),
	.nRESET(nRESET),
	.En(En),
	.PS2_CLK(PS2_CLK),
	.PS2_DATA(PS2_DATA),
	
	.DATA(DATA),
	.DONE(DONE));
	
initial begin
	$dumpvars(0, PS2Driver_test);
	
	CLK = 0;
	forever #(`CLK_PERIOD/2) CLK = ~CLK;
	end
	
	reg [3:0] CLKCOUNTER = 0;
	
	always @(posedge CLK) CLKCOUNTER <= CLKCOUNTER + 1;
	always @(posedge CLK) En <= ~|CLKCOUNTER;
	
	initial begin
	nRESET <= 0;
	PS2_CLK <= 1;
	PS2_DATA<= 1'bx;
	repeat (10) @(posedge CLK);
	
	nRESET <= 1;
	repeat (5) @(posedge En);
	
	repeat (11) begin
		while(~CLKCOUNTER[3]) @(posedge CLK);
		PS2_DATA <= $urandom_range(9,8);
		PS2_CLK  <= 0;
		while(CLKCOUNTER[3])  @(negedge CLK);
		PS2_CLK  <= 1;
	end
	
	repeat (5) @(posedge En);
	
	$finish;
end
	
endmodule
	
	
