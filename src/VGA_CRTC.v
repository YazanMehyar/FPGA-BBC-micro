`include "TOP.vh"

module VGA_CRTC(
	input PIXELCLK,
	input CRTC_en,
	input PROC_en,
	input PHI_2,
	input nCS,
	input RnW,
	input RS,
	input nRESET,

	inout [7:0] DATABUS,

	output reg [13:0] FRAMESTORE_ADR,
	output reg [4:0]  ROW_ADDRESS,
	output DISEN,
	output VGA_HS,
	output VGA_VS,
	output CURSOR);

reg [13:0] start_address;
reg [13:0] cursor_adr;
reg [4:0]  address_reg;

reg [7:0] horz_display;
reg [6:0] vert_display;
reg [4:0] max_scanline;
reg [4:0] cursor_start_row;
reg [4:0] cursor_end_row;
reg [1:0] cursor_blink_mode;

/****************************************************************************************/

assign DATABUS = (~nCS & PHI_2 & RnW & nRESET)? DATABUS_out : 8'hzz;
assign DISEN   = VGA_DISEN & |HDISPLAY_COUNT[7:1] & |VDISPLAY_COUNT;
assign CURSOR  = cursor_poximity & cursor_point & nRESET & cursor_display;

reg [7:0] DATABUS_out;
always @ ( * ) begin
	case ({address_reg[4],address_reg[0]})
		2'b00: DATABUS_out = {2'b00,cursor_adr[13:8]};
		2'b01: DATABUS_out = cursor_adr[7:0];
		default: DATABUS_out = 8'hxx;
	endcase
end

always @ (posedge PIXELCLK) begin
	if(~nCS & ~RnW & PROC_en)
		if(RS)
			case (address_reg) // light pen register is not writable.
				5'h01: horz_display  <= DATABUS;
				5'h06: vert_display  <= DATABUS[6:0];
				5'h09: max_scanline  <= DATABUS[4:0];
				5'h0A: {cursor_blink_mode, cursor_start_row} <= DATABUS[6:0];
				5'h0B: cursor_end_row <= DATABUS[4:0];
				5'h0C: start_address[13:8]<= DATABUS[5:0];
				5'h0D: start_address[7:0] <= DATABUS;
				5'h0E: cursor_adr[13:8]   <= DATABUS[5:0];
				5'h0F: cursor_adr[7:0]    <= DATABUS;
			endcase
		else address_reg <= DATABUS[4:0];
end

/****************************************************************************************/

wire NEWLINE;
wire NEWSCREEN;
wire VGA_DISEN;

VGA vga(
	.PIXELCLK(PIXELCLK),
	.CRTC_en(CRTC_en),
	.nRESET(nRESET),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.NEWLINE(NEWLINE),
	.NEWSCREEN(NEWSCREEN),
	.DISEN(VGA_DISEN)
);


/****************************************************************************************/

// horizontal control
reg [7:0] HDISPLAY_COUNT;

always @ (posedge PIXELCLK) begin
	if(~nRESET)
		HDISPLAY_COUNT <= horz_display;
	else if(CRTC_en)
		if(NEWLINE)
			HDISPLAY_COUNT <= horz_display;
		else if(DISEN)
			HDISPLAY_COUNT <= HDISPLAY_COUNT - 1;
end

/****************************************************************************************/
// vertical control

reg [6:0] VDISPLAY_COUNT;

wire NEWvCHAR = ROW_ADDRESS == max_scanline && NEWLINE;

always @ (posedge PIXELCLK) begin
	if(~nRESET)
		VDISPLAY_COUNT <= vert_display;
 	else if(CRTC_en)
		if(NEWSCREEN)
			VDISPLAY_COUNT <= vert_display;
		else if(NEWvCHAR & |VDISPLAY_COUNT)
			VDISPLAY_COUNT <= VDISPLAY_COUNT - 1;
end

/****************************************************************************************/
// Address buses

reg [13:0] scanline_start_adr;

always @ (posedge PIXELCLK) begin
	if(~nRESET) begin
		FRAMESTORE_ADR		<= 0;
		scanline_start_adr	<= 0;
	end else if(CRTC_en)
		if(NEWSCREEN) begin
	        FRAMESTORE_ADR		<= start_address;
	        scanline_start_adr	<= start_address;
	    end else if(NEWvCHAR) begin
	        FRAMESTORE_ADR		<= scanline_start_adr + horz_display;
	        scanline_start_adr	<= scanline_start_adr + horz_display;
	    end else if(NEWLINE) begin
	        FRAMESTORE_ADR		<= scanline_start_adr;
	    end else begin
	        FRAMESTORE_ADR		<= FRAMESTORE_ADR + 1;
	    end
end

reg SINGLE;
always @ (posedge PIXELCLK) begin
	if(~nRESET) begin
		ROW_ADDRESS <= 0;
		SINGLE		<= 0;
	end else if(CRTC_en)
		if(NEWvCHAR | NEWSCREEN) begin
			ROW_ADDRESS <= 0;
			SINGLE <= 1;
		end else if(NEWLINE & ~SINGLE) begin
			ROW_ADDRESS <= ROW_ADDRESS + 1;
			SINGLE <= 1;
		end else SINGLE <= 0;
end

/****************************************************************************************/
// Cursor
wire cursor_point    = FRAMESTORE_ADR == cursor_adr && DISEN;
wire cursor_poximity = ROW_ADDRESS >= cursor_start_row && ROW_ADDRESS <= cursor_end_row;

reg [5:0] cursor_blink_count;
reg cursor_display;
always @ (posedge PIXELCLK) begin
	if(~nRESET) begin
		cursor_blink_count <= 0;
		cursor_display <= 0;
	end else if(NEWSCREEN&CRTC_en) begin
		cursor_blink_count <= cursor_blink_count + 1;
		case (cursor_blink_mode)
			2'b00: cursor_display <= 1;
			2'b01: cursor_display <= 0;
			2'b10: cursor_display <= cursor_blink_count[4];
			2'b11: cursor_display <= cursor_blink_count[5];
			default: cursor_display <= 1'bx;
		endcase
	end
end

endmodule
