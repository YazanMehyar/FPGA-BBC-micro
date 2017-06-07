`include "TOP.vh"
module Sound_Generator_test ();

	initial $dumpvars(0, Sound_Generator_test);

	// inputs
	wire pCLK;
	wire CLK_en;
	reg  nWE;
	reg  [7:0] DATA;

	// output
	wire PWM;

	Sound_Generator sound(
		.CLK(pCLK),
		.CLK_en(CLK_en),
		.nWE(nWE),
		.DATA(DATA),
		.PWM(PWM)
		);

/****************************************************************************************/
	task write_data;
	input [7:0] data;
	begin
		@(posedge CLK_en)
		DATA <= data;
		nWE  <= 0;
		@(posedge CLK_en)
		nWE  <= 1;
	end
	endtask

	reg CLK;
	initial begin
		CLK = 0;
		forever #(`CLKPERIOD/2) CLK = ~CLK;
	end

	Timing_Generator t(
		.CLK100MHZ(CLK),
		.PIXELCLK(pCLK),
		.PROC_en(CLK_en)
		);

	// Test Procedure
	initial begin
		nWE <= 1;
		repeat (20) @(posedge CLK_en);

		// set TONE frequency
		write_data(8'h80); write_data(8'h04);
		write_data(8'hA0); write_data(8'h02);
		write_data(8'hC0); write_data(8'h01);

		// noise control
		write_data(8'hE4);

		// set volume
		write_data(8'h90);
		write_data(8'hBF);
		write_data(8'hDF);
		write_data(8'hF0);

		repeat(100000) @(posedge CLK_en);
		$finish;
	end

endmodule // Sound_Generator_test
