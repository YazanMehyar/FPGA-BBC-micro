module VideoULA (
	input PIXELCLK,
	input nRESET,
	input A0,
	input nCS,
	input DISEN,
	input CURSOR,
	input [7:0] DATA,
	input [7:0] pDATA,

	output reg CLK_PROC,
	output reg CLK_hPROC,
	output reg CLK_RAM,
	output CLK_CRTC,
	output REDout,
	output GREENout,
	output BLUEout);

/****************************************************************************************/

	reg CLK_2RAM;
	reg [7:0] CONTROL = 0;
	reg [7:0] SHIFT_reg = 0;
	reg [3:0] PALETTE_mem [0:15];

/****************************************************************************************/
	initial begin
		CLK_hPROC = 0;
		CLK_PROC= 0;
		CLK_RAM = 0;
		CLK_2RAM = 0;
	end

	always @ (posedge PIXELCLK) CLK_2RAM  <= #1 ~CLK_2RAM;
	always @ (posedge CLK_2RAM) CLK_RAM   <= #1 ~CLK_RAM;
	always @ (posedge CLK_RAM)  CLK_PROC  <= #1 ~CLK_PROC;
	always @ (posedge CLK_PROC) CLK_hPROC <= #1 ~CLK_hPROC;

	assign CLK_CRTC = CONTROL[4]? CLK_PROC : CLK_hPROC;

/****************************************************************************************/

	wire CRTC_posedge;
	reg  prev_CLKCRTC;
	always @ (posedge PIXELCLK) begin
		prev_CLKCRTC <= CLK_CRTC;
	end
	assign CRTC_posedge = CLK_CRTC & ~prev_CLKCRTC;

	reg SHIFT_en; // wire
	always @ ( * ) begin
		case (CONTROL[3:2])
			2'b00: SHIFT_en = CLK_2RAM&CLK_RAM&~CLK_PROC;
			2'b01: SHIFT_en = CLK_2RAM&CLK_RAM;
			2'b10: SHIFT_en = CLK_2RAM;
			2'b11: SHIFT_en = 1;
			default: SHIFT_en = 1'bx;
		endcase
	end

	always @ (posedge PIXELCLK) begin
		if(CRTC_posedge)	SHIFT_reg <= DATA;
		else if(SHIFT_en)	SHIFT_reg <= {SHIFT_reg[6:0],1'b1};
	end

/****************************************************************************************/

	wire [3:0] PALETTE_out = PALETTE_mem[{SHIFT_reg[7],SHIFT_reg[5],SHIFT_reg[3],SHIFT_reg[1]}];
	always @ (posedge CLK_PROC) begin
		if(~nCS)
		 	if(A0)  PALETTE_mem[pDATA[7:4]] <= pDATA[3:0];
			else	CONTROL <= pDATA;
	end

/****************************************************************************************/

	reg [2:0] CURSOR_seg;
	reg CURSOR_out;

	always @ (posedge PIXELCLK) begin
		if(~nRESET) CURSOR_seg <= 3'b000;
		else if(CRTC_posedge) begin
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
