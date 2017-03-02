`include "TOP.vh"

module VideoULA (
	input PIXELCLK,
	input nRESET,
	input dRAM_en,
	input RAM_en,
	input PROC_en,
	input hPROC_en,
	input A0,
	input nCS,
	input DISEN,
	input CURSOR,
	input [7:0] vDATA,
	input [7:0] pDATA,

	output CRTC_en,
	output REDout,
	output GREENout,
	output BLUEout);

/****************************************************************************************/

	reg [7:0] CONTROL = 0;
	reg [7:0] SHIFT_reg = 0;
	reg [3:0] PALETTE_mem [0:15];

/****************************************************************************************/
	assign CRTC_en = CONTROL[4]? PROC_en : hPROC_en;

	reg hPROC_SYNC;
	always @ ( posedge PIXELCLK ) begin
		if(PROC_en) hPROC_SYNC <= hPROC_en;
	end

	wire NEXT_vBYTE = CONTROL[4]? RAM_en&~PROC_en : RAM_en&PROC_en&hPROC_en;
/****************************************************************************************/

	reg SHIFT_en; // wire
	always @ ( * ) begin
		case (CONTROL[3:2])
			2'b00: SHIFT_en = PROC_en;
			2'b01: SHIFT_en = RAM_en;
			2'b10: SHIFT_en = dRAM_en;
			2'b11: SHIFT_en = 1'b1;
			default: SHIFT_en = 1'bx;
		endcase
	end

	always @ ( posedge PIXELCLK ) begin
		if(NEXT_vBYTE)	SHIFT_reg <= vDATA;
		else if(SHIFT_en)	SHIFT_reg <= {SHIFT_reg[6:0],1'b1};
	end

/****************************************************************************************/

	wire [3:0] PALETTE_out = PALETTE_mem[{SHIFT_reg[7],SHIFT_reg[5],
										  SHIFT_reg[3],SHIFT_reg[1]}];
	always @ ( posedge PIXELCLK ) begin
		if(PROC_en)
			if(~nCS)
		 		if(A0)  PALETTE_mem[pDATA[7:4]] <= pDATA[3:0];
				else	CONTROL <= pDATA;
	end

/****************************************************************************************/

	reg [2:0] CURSOR_seg;
	reg CURSOR_out;

	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) CURSOR_seg <= 3'b000;
		else if(NEXT_vBYTE) begin
			if(CURSOR)	CURSOR_seg <= 3'b001;
			else		CURSOR_seg <= CURSOR_seg << 1;
			CURSOR_out <= CURSOR&CONTROL[7]
							| CURSOR_seg[0]&CONTROL[6]
							| CURSOR_seg[1]&CONTROL[5]
							| CURSOR_seg[2]&CONTROL[5];
		end
	end


/****************************************************************************************/

	wire FLASH = ~(PALETTE_out[3]&CONTROL[0]);
	wire [2:0] PIXEL_COLOR = DISEN? FLASH? ~PALETTE_out[2:0] : PALETTE_out[2:0] : 3'b000;
	assign {BLUEout,GREENout,REDout} = CURSOR_out? ~PIXEL_COLOR : PIXEL_COLOR;

endmodule // VideoULA
