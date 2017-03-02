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

	output reg [13:0] framestore_adr,
	output reg [4:0]  scanline_row,
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

wire ENDofLINE;
wire NEWSCREEN;
wire VGA_DISEN;

VGA vga(
	.PIXELCLK(PIXELCLK),
	.nRESET(nRESET),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.ENDofLINE(ENDofLINE),
	.NEWSCREEN(NEWSCREEN),
	.DISEN(VGA_DISEN)
);


/****************************************************************************************/

// horizontal control
reg [7:0] HDISPLAY_COUNT;

always @ (posedge PIXELCLK) begin
	if(~nRESET | ENDofLINE)
		HDISPLAY_COUNT <= horz_display;
	else if(DISEN & CRTC_en)
		HDISPLAY_COUNT <= HDISPLAY_COUNT - 1;
end

/****************************************************************************************/
// vertical control

reg [6:0] VDISPLAY_COUNT;

wire next_charline = scanline_row == max_scanline && ENDofLINE&VGA_DISEN;

always @ (posedge PIXELCLK) begin
	if(~nRESET | NEWSCREEN)
		VDISPLAY_COUNT <= vert_display;
	else if(next_charline & |VDISPLAY_COUNT)
		VDISPLAY_COUNT <= VDISPLAY_COUNT - 1;
end

/****************************************************************************************/
// Address buses

reg [13:0] scanline_start_adr;

always @ (posedge PIXELCLK) begin
	if(~nRESET) begin
		framestore_adr		<= 0;
		scanline_start_adr	<= 0;
	end if(NEWSCREEN) begin
        framestore_adr		<= start_address;
        scanline_start_adr	<= start_address;
    end else if(next_charline) begin
        framestore_adr		<= scanline_start_adr + horz_display;
        scanline_start_adr	<= scanline_start_adr + horz_display;
    end else if(ENDofLINE&VGA_DISEN) begin
        framestore_adr		<= scanline_start_adr;
    end else if(CRTC_en&DISEN) begin
        framestore_adr		<= framestore_adr + 1;
    end
end

always @ (posedge PIXELCLK) begin
	if(~nRESET | next_charline | NEWSCREEN)
		scanline_row <= 0;
	else if(ENDofLINE&VGA_DISEN)
		scanline_row <= scanline_row + 1;
end

/****************************************************************************************/
// Cursor
wire cursor_point    = framestore_adr == cursor_adr && DISEN;
wire cursor_poximity = scanline_row >= cursor_start_row && scanline_row <= cursor_end_row;

reg [4:0] cursor_blink_count;
reg cursor_display;
always @ (posedge PIXELCLK) begin
	if(~nRESET) begin
		cursor_blink_count <= 0;
		cursor_display <= 0;
	end else if(NEWSCREEN) begin
		cursor_blink_count <= cursor_blink_count + 1;
		case (cursor_blink_mode)
			2'b00: cursor_display <= 1;
			2'b01: cursor_display <= 0;
			2'b10: cursor_display <= cursor_blink_count[3];
			2'b11: cursor_display <= cursor_blink_count[4];
			default: cursor_display <= 1'bx;
		endcase
	end
end

endmodule
