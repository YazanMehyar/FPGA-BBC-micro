`include "TOP.vh"
module Sound_Generator_test ();

	initial $dumpvars(0, Sound_Generator_test);

	// inputs
	wire pclk;
	wire clk_en;
	reg  nWE;
	reg  [7:0] DATA;

	// output
	wire PWM;

	Sound_Generator sound(
		.clk(pclk),
		.clk_en(clk_en),
		.nWE(nWE),
		.DATA(DATA),
		.PWM(PWM)
		);

/****************************************************************************************/
	task write_data;
	input [7:0] data;
	begin
		@(posedge clk_en)
		DATA <= data;
		nWE  <= 0;
		@(posedge clk_en)
		nWE  <= 1;
	end
	endtask

	reg clk;
	initial begin
		clk = 0;
		forever #(`CLKPERIOD/2) clk = ~clk;
	end

	Timing_Generator t(
		.CLK100MHZ(clk),
		.PIXELCLK(pclk),
		.PROC_en(clk_en)
		);

	// Test Procedure
	initial begin
		nWE <= 1;
		repeat (20) @(posedge clk_en);

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

		repeat(100000) @(posedge clk_en);
		$finish;
	end

endmodule // Sound_Generator_test
