module Keyboard_test();

	`define CLK_PERIOD 10

	reg PROC_CLK;
	initial begin
		$dumpvars(0,Keyboard_test);
		PROC_CLK = 0;
		forever #(`CLK_PERIOD/2) PROC_CLK = ~PROC_CLK;
	end
	
	// inputs
	reg PS2_CLK;
	reg PS2_DATA;
	reg nRESET;
	reg COLUMN;
	reg AUTOSCAN;
	reg ROW;
	
	// outputs
	wire COLUMN_MATCH;
	wire ROW_MATCH;
	
	Keyboard k(
	.CLK_hPROC(PROC_CLK),
	.nRESET(nRESET),
	.autoscan(AUTOSCAN),
	.column(COLUMN),
	.row(ROW),
	.PS2_CLK(PS2_CLK),
	.PS2_DATA(PS2_DATA),
	.column_match(COLUMN_MATCH),
	.row_match(ROW_MATCH)
	);
	
	
/**************************************************************************************************/

	// Generate slow PS2_CLK
	reg [3:0] CLK_COUNTER = 0;
	always @ (posedge PROC_CLK) CLK_COUNTER <= CLK_COUNTER + 1;
	
	always @ (*) PS2_CLK = CLK_COUNTER[3];
	
	`include "PS2.vh"
	
	
/**************************************************************************************************/

	initial begin
		nRESET <= 0;
		repeat (20) @(posedge PROC_CLK);
		
		nRESET <= 1;
		AUTOSCAN <= 1;
		PS2_SEND(8'h1C); // send valid key 'a'
		repeat (20) @(posedge PROC_CLK);
		
		PS2_SEND(8'hF0); // send release code
		PS2_SEND(8'h1C); // followed by key
		repeat (100) @(posedge PROC_CLK);
		$stop;
	end
	
endmodule
