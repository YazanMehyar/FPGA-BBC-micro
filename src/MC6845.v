/*
TODO
	- Cursor blink rate
	- Light strobe
	- Interlace modes
	- Display skew
	- Cursor skew
*/


module MC6845 (
	input char_clk,
	input en,
	input nCS,
	input RnW,
	input RS,
	input nRESET,
	input LPSTB,

	inout [7:0] data_bus,

	output reg [13:0] framestore_adr,
	output reg [4:0]  scanline_row,
	output reg display_en,
	output reg h_sync,
	output reg v_sync,
	output reg cursor
	);

reg [13:0] start_address;
reg [13:0] cursor_adr;
reg [13:0] lightpen_adr;
reg [4:0]  address_reg;

// horizontal control registers
reg [7:0] horz_display;
reg [7:0] horz_syncpos;
reg [3:0] horz_pulse;
reg [7:0] horz_total;

// vertical control registers
reg [6:0] vert_display;
reg [6:0] vert_syncpos;
reg [3:0] vert_pulse;
reg [6:0] vert_total;
reg [4:0] vert_fraction;

reg [1:0] interlace_mode;

reg [4:0] max_scanline;
reg [4:0] cursor_start_row;
reg [4:0] cursor_end_row;

reg [1:0] cursor_blink_mode;
// wires
reg [7:0] data_bus_out;

/**************************************************************************************************/

assign data_bus = ~nCS&en&RnW? data_bus_out : 8'hzz;

always @ ( * ) begin
	case ({address_reg[4],address_reg[0]})
		2'b00: data_bus_out = {2'b00,cursor_adr[13:8]};
		2'b01: data_bus_out = cursor_adr[7:0];
		2'b10: data_bus_out = {2'b00,lightpen_adr[13:8]};
		2'b11: data_bus_out = lightpen_adr[7:0];
		default: data_bus_out = 8'hxx;
	endcase
end

always @ (negedge en) begin
	if(~nCS & ~RnW)
		if(RS)
			case (address_reg) // light pen register is not writable.
				5'h00: horz_total    <= data_bus;
				5'h01: horz_display  <= data_bus;
				5'h02: horz_syncpos  <= data_bus;
				5'h03: {vert_pulse,horz_pulse} <= data_bus;
				5'h04: vert_total    <= data_bus[6:0];
				5'h05: vert_fraction <= data_bus[4:0];
				5'h06: vert_display  <= data_bus[6:0];
				5'h07: vert_syncpos  <= data_bus[6:0];
				5'h08: interlace_mode<= data_bus[1:0];
				5'h09: max_scanline  <= data_bus[4:0];
				5'h0A: {cursor_blink_mode, cursor_start_row} <= data_bus[6:0];
				5'h0B: cursor_end_row <= data_bus[4:0];
				5'h0C: start_address[13:8]<= data_bus[5:0];
				5'h0D: start_address[7:0] <= data_bus;
				5'h0E: cursor_adr[13:8]   <= data_bus[5:0];
				5'h0F: cursor_adr[7:0]    <= data_bus;
			endcase
		else address_reg <= data_bus[4:0];
end

/**************************************************************************************************/
// horizontal control
reg [3:0] hz_pulse_count;
reg [7:0] hz_total_count;

wire [7:0] nxt_hz_total_count = hz_total_count + 1;
wire [3:0] nxt_hz_pulse_count = hz_pulse_count + 1;

wire scanline_end  = hz_total_count == horz_total;
wire hz_sync_end   = hz_pulse_count == horz_pulse;
wire hz_display_end= nxt_hz_total_count == horz_display;
wire hz_sync_start = nxt_hz_total_count == horz_syncpos && |horz_pulse;

always @ (negedge char_clk) begin
	if(~nRESET | scanline_end) begin
		hz_total_count <= 0;
		hz_pulse_count <= 0;
	end else begin
		hz_total_count <= nxt_hz_total_count;
		if(h_sync | hz_sync_start)
			hz_pulse_count <= nxt_hz_pulse_count;
	end
end

/**************************************************************************************************/
// vertical control

reg [3:0] vt_pulse_count;
reg [6:0] vt_total_count;
reg [4:0] vt_fraction_count;

reg vt_display;
reg fraction_sync_phase;

wire [3:0] nxt_vt_pulse_count = vt_pulse_count + 1;
wire [6:0] nxt_vt_total_count = vt_total_count + 1;
wire [4:0] nxt_vt_fraction_count = vt_fraction_count + 1;

wire next_row			= scanline_row == max_scanline && scanline_end;
wire last_row			= vt_total_count == vert_total;
wire vt_display_end		= nxt_vt_total_count == vert_display;
wire vt_sync_start		= nxt_vt_total_count == vert_syncpos && next_row;
wire vt_sync_end		= vt_pulse_count == vert_pulse;
wire vt_fraction_start	= last_row & next_row & |vert_fraction;
wire vt_fraction_end	= nxt_vt_fraction_count == vert_fraction;

wire screen_end 		= last_row & next_row & ~|vert_fraction
							| vt_fraction_end & fraction_sync_phase & scanline_end;

always @ (negedge char_clk) begin
	if(~nRESET | screen_end) begin
		vt_total_count   <= 0;
		vt_pulse_count   <= 0;
		vt_fraction_count<= 0;
	end else if(scanline_end) begin
		if(next_row)
			vt_total_count <= nxt_vt_total_count;

		if(vt_sync_start|v_sync)
			vt_pulse_count <= nxt_vt_pulse_count;

		if(vt_fraction_start|fraction_sync_phase)
			vt_fraction_count <= nxt_vt_fraction_count;
	end
end

always @ (negedge char_clk) begin
	if(~nRESET)		fraction_sync_phase <= 0;
	else if(scanline_end)
		if(vt_fraction_start)		fraction_sync_phase <= 1;
		else if(vt_fraction_end)	fraction_sync_phase <= 0;
end

always @ (negedge char_clk) begin
	if(~nRESET)				vt_display <= 0;
	else if(screen_end)		vt_display <= 1;
	else if(vt_display & next_row)	vt_display <= ~vt_display_end;
end

/**************************************************************************************************/
// Display signals

always @ (negedge char_clk) begin
	if(~nRESET)	h_sync <= 0;
	else if(vt_display)
		if(hz_sync_start)		h_sync <= 1;
		else if(hz_sync_end)	h_sync <= 0;
end

always @ (negedge char_clk) begin
	if(~nRESET)	v_sync <= 0;
	else if(scanline_end & vt_display)
		if(vt_sync_start)		v_sync <= 1;
		else if(vt_sync_end)	v_sync <= 0;
end

always @ (negedge char_clk) begin
	if(~nRESET)	display_en <= 0;
	else if(display_en)	display_en <= ~hz_display_end;
	else				display_en <= scanline_end & vt_display | screen_end;
end

/**************************************************************************************************/
// Address buses

reg [13:0] scanline_start_adr;

always @ (negedge char_clk) begin
	if(~nRESET) begin
		framestore_adr		<= 0;
		scanline_start_adr	<= 0;
	end else if(screen_end) begin
		framestore_adr		<= start_address;
		scanline_start_adr	<= start_address;
	end else if(next_row) begin
		framestore_adr		<= scanline_start_adr + horz_display;
		scanline_start_adr	<= scanline_start_adr + horz_display;
	end else if(scanline_end) begin
		framestore_adr		<= scanline_start_adr;
	end else begin
		framestore_adr		<= framestore_adr + 1;
	end
end

wire [4:0] nxt_scanline_row = (next_row|screen_end)? 0 : scanline_row + 1;
always @ (negedge char_clk) begin
	if(~nRESET)				scanline_row <= 0;
	else if(scanline_end)	scanline_row <= nxt_scanline_row;
end

/**************************************************************************************************/
// Cursor
wire cursor_point = framestore_adr == cursor_adr;

reg cursor_poximity;
always @ (negedge char_clk) begin
	if(scanline_end)
		if(cursor_start_row == nxt_scanline_row) cursor_poximity <= 1;
		else if(cursor_end_row == scanline_row)  cursor_poximity <= 0;
end

always @ ( * ) cursor = cursor_poximity & cursor_point & nRESET;

endmodule // MC6845
