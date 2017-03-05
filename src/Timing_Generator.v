`include "TOP.vh"

module Timing_Generator(
	input CLK100MHZ,

	output reg PHI_2,
	output PIXELCLK,
	output PROC_en,
	output hPROC_en,
	output RAM_en,
	output dRAM_en,
	output CRTCF_en,
	output reg V_TURN);

	//NB Both counters are initialised to aid with simulation

	// Highest resolution clock
	reg PIXELCOUNT = 0;
	always @ (posedge CLK100MHZ) PIXELCOUNT <= ~PIXELCOUNT;
	assign PIXELCLK = PIXELCOUNT;
	
	reg [4:0] MASTER_COUNTER = 0;
	always @(posedge PIXELCLK)	MASTER_COUNTER <= MASTER_COUNTER + 4'h1;

	assign dRAM_en = MASTER_COUNTER[0];
	assign RAM_en  = &MASTER_COUNTER[1:0];
	assign CRTCF_en = &MASTER_COUNTER[2:0];
	assign PROC_en = &MASTER_COUNTER[3:0];
	assign hPROC_en= &MASTER_COUNTER[4:0];

	always @ (posedge PIXELCLK)
		if(CRTCF_en) PHI_2 <= ~PROC_en;
		
	always @ (posedge PIXELCLK)
		if(RAM_en)  V_TURN <= ~CRTCF_en;

endmodule
