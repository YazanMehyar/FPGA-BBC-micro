`include "TOP.vh"

module Timing_Generator(
	input CLK100MHZ,

	output reg PHI_2,
	output PIXELCLK,
	output PROC_en,
	output hPROC_en,
	output RAM_en,
	output dRAM_en);

	//NB Both counters are initialised to aid with simulation

	// Highest resolution clock
	reg [1:0] PIXELCOUNT = 0;
	always @ (posedge CLK100MHZ) PIXELCOUNT <= PIXELCOUNT + 2'b01;

	assign PIXELCLK = PIXELCOUNT[1];

	reg [3:0] MASTER_COUNTER = 0;
	always @(posedge PIXELCLK)	MASTER_COUNTER <= MASTER_COUNTER + 4'h1;

	assign dRAM_en = MASTER_COUNTER[0];
	assign RAM_en  = &MASTER_COUNTER[1:0];
	assign PROC_en = &MASTER_COUNTER[2:0];
	assign hPROC_en= &MASTER_COUNTER[3:0];

	always @ (posedge PIXELCLK)
		if(RAM_en) PHI_2 <= ~PROC_en;

endmodule
