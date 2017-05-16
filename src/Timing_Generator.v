`include "TOP.vh"

module Timing_Generator(
	input CLK100MHZ,

	output PIXELCLK,
	output PROC_en,
	output hPROC_en,
	output RAM_en,
	output dRAM_en,
	output CRTCF_en,
	output CRTCS_en,
	output reg TTX_en,
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
	assign CRTCS_en = &MASTER_COUNTER[3:0];
	
	reg [3:0] TTX_COUNT;
	always @ (posedge PIXELCLK)
		if(CRTCS_en) TTX_COUNT <= 0;
		else 		 TTX_COUNT <= TTX_COUNT + 1;
		
	always @ (*) case(TTX_COUNT)
		4'h3: TTX_en = 1;
		4'h5: TTX_en = 1;
		4'h7: TTX_en = 1;
		4'h9: TTX_en = 1;
		4'hB: TTX_en = 1;
		4'hD: TTX_en = 1;
		default: TTX_en = 0;
	endcase

	reg [2:0] PROC_CLK_GEN = 3'b001;
	always @(posedge PIXELCLK)
		if(CRTCF_en) PROC_CLK_GEN <= {PROC_CLK_GEN[1:0],PROC_CLK_GEN[2]};

	assign PROC_en = PROC_CLK_GEN[2]&CRTCF_en;
	assign hPROC_en= PROC_CLK_GEN[2]&CRTCS_en;

	always @ (posedge PIXELCLK)
		if(RAM_en)  V_TURN <= CRTCF_en;

endmodule
