`include "TOP.vh"

module Filter_test();

	// input
	reg CLK;
	reg CLK_en;
	reg READY_en;
	reg nRESET;
	reg SIGNAL;
	
	// output
	wire FILTERED_SIGNAL;
	wire READY;
	
	Filter #(
		.DEBOUNCE_COUNT(5),
		.PRESET_VALUE(1)
	) f (
		.CLK(CLK),
		.CLK_en(CLK_en),
		.READY_en(READY_en),
		.nRESET(nRESET),
		.SIGNAL(SIGNAL),
		.FILTERED_SIGNAL(FILTERED_SIGNAL),
		.READY(READY)
	);
	
	event START_LOG;
	initial begin
		@(START_LOG);
		$dumpvars(0, Filter_test);
	end
	
	initial CLK = 0;
	always #(`CLKPERIOD) CLK = ~CLK;
	
	reg [3:0] COUNTER = 0;
	always @ (posedge CLK) COUNTER <= COUNTER + 1;
	always @ (*) CLK_en   = ~|COUNTER;
	always @ (*) READY_en = ~|COUNTER[1:0];
	
/**************************************************************************************************/

	initial begin
		-> START_LOG;
		nRESET <= 1;
		SIGNAL <= 0;
		repeat (2) @(posedge CLK);
		nRESET <= 0;
		repeat (2) @(posedge CLK_en);
		nRESET <= 1;
		repeat (10) @(posedge CLK_en);
		SIGNAL <= 1;
		repeat (10) @(posedge CLK_en);
		repeat (2) @(posedge CLK);
		$finish;
	end

endmodule
