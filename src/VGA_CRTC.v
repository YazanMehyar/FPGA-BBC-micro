module VGA_CRTC(
	input PIXELCLK,
	input CHARCLK,
	input En,
	input nCS,
	input RnW,
	input RS,
	input nRESET,

	inout [7:0] DATABUS,

	output reg [13:0] framestore_adr,
	output reg [4:0]  scanline_row,
	output reg DISEN,
	output H_SYNC,
	output V_SYNC,
	output CURSOR
);

reg [13:0] start_address;
reg [13:0] cursor_adr;
reg [13:0] lightpen_adr;
reg [4:0]  address_reg;

reg [7:0] horz_display;
reg [6:0] vert_display;
reg [1:0] interlace_mode;
reg [4:0] max_scanline;
reg [4:0] cursor_start_row;
reg [4:0] cursor_end_row;
reg [1:0] cursor_blink_mode;

/****************************************************************************************/

assign DATABUS = (~nCS & En & RnW & nRESET)? DATABUS_out : 8'hzz;
assign CURSOR  = cursor_poximity & cursor_point & nRESET & cursor_display;

reg [7:0] DATABUS_out;
always @ ( * ) begin
	case ({address_reg[4],address_reg[0]})
		2'b00: DATABUS_out = {2'b00,cursor_adr[13:8]};
		2'b01: DATABUS_out = cursor_adr[7:0];
		2'b10: DATABUS_out = {2'b00,lightpen_adr[13:8]};
		2'b11: DATABUS_out = lightpen_adr[7:0];
		default: DATABUS_out = 8'hxx;
	endcase
end

always @ (negedge En) begin
	if(~nCS & ~RnW)
		if(RS)
			case (address_reg) // light pen register is not writable.
				5'h01: horz_display  <= DATABUS;
				5'h06: vert_display  <= DATABUS[6:0];
				5'h08: interlace_mode<= DATABUS[1:0];
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

wire scanline_end;
wire screen_end;
wire VGA_DISEN;

VGA vga(
	.PIXELCLK(PIXELCLK),
	.nRESET(nRESET),
	.VGA_HSYNC(H_SYNC),
	.VGA_VSYNC(V_SYNC),
	.NEWLINE(scanline_end),
	.NEWSCREEN(screen_end),
	.DISEN(VGA_DISEN)
);


/****************************************************************************************/
reg prev_CHARCLK;
always @ (posedge PIXELCLK) prev_CHARCLK <= CHARCLK;

wire CHAR_en = ~CHARCLK & prev_CHARCLK;

reg CHAR_SYNC;
always @ (posedge PIXELCLK) begin
    if(scanline_end) CHAR_SYNC <= 0;
    else if(CHAR_en) CHAR_SYNC <= 1;
end

// horizontal control
reg [7:0] HDISPLAY_COUNT;

always @ (posedge PIXELCLK) begin
	if(~nRESET | scanline_end)
		HDISPLAY_COUNT <= horz_display;
	else if(|HDISPLAY_COUNT[7:1] & VGA_DISEN & CHAR_en & CHAR_SYNC)
		HDISPLAY_COUNT <= HDISPLAY_COUNT - 1;
end

/****************************************************************************************/
// vertical control

reg [6:0] VDISPLAY_COUNT;

wire next_charline = scanline_row == max_scanline && scanline_end;

always @ (posedge PIXELCLK) begin
	if(~nRESET | screen_end)
		VDISPLAY_COUNT <= vert_display;
	else if(next_charline & |VDISPLAY_COUNT)
		VDISPLAY_COUNT <= VDISPLAY_COUNT - 1;
end

/****************************************************************************************/

always @(posedge PIXELCLK) begin
    if(CHAR_en & CHAR_SYNC)
        DISEN <= VGA_DISEN & |HDISPLAY_COUNT[7:1] & |VDISPLAY_COUNT;
end

/****************************************************************************************/
// Address buses

reg [13:0] scanline_start_adr;

always @ (posedge PIXELCLK) begin
	if(~nRESET) begin
		framestore_adr		<= 0;
		scanline_start_adr	<= 0;
	end if(screen_end) begin
        framestore_adr		<= start_address;
        scanline_start_adr	<= start_address;
    end else if(next_charline) begin
        framestore_adr		<= scanline_start_adr + horz_display;
        scanline_start_adr	<= scanline_start_adr + horz_display;
    end else if(scanline_end) begin
        framestore_adr		<= scanline_start_adr;
    end else if(CHAR_en & CHAR_SYNC) begin
        framestore_adr		<= framestore_adr + 1;
    end
end

always @ (posedge PIXELCLK) begin
	if(~nRESET | next_charline | screen_end)
		scanline_row <= 0;
	else if(scanline_end)
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
	end else if(screen_end & scanline_end) begin
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