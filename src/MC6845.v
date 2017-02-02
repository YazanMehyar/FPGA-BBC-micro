/*
TODO
	- Interlace modes
	- Display skew
	- Cursor skew
	- Cursor blink rate
	- Light strobe
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
	output reg [4:0]  char_scanline,
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
reg [3:0] horz_pulsew;
reg [7:0] horz_total;

// vertical control registers
reg [6:0] vert_display;
reg [6:0] vert_syncpos;
reg [3:0] vert_pulsew;
reg [6:0] vert_total;
reg [4:0] vert_fraction;

reg [4:0] max_scanline;
reg [4:0] cursor_start;
reg [4:0] cursor_end;

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
			case (address_reg)
				5'h00: horz_total    <= data_bus;
				5'h01: horz_display  <= data_bus;
				5'h02: horz_syncpos  <= data_bus;
				5'h03: {vert_pulsew,horz_pulsew} <= data_bus;
				5'h04: vert_total    <= data_bus[6:0];
				5'h05: vert_fraction <= data_bus[4:0];
				5'h06: vert_display  <= data_bus[6:0];
				5'h07: vert_syncpos  <= data_bus[6:0];
				5'h08:;
				5'h09: max_scanline  <= data_bus[4:0];
				5'h0A: {cursor_blink_mode, cursor_start} <= data_bus[6:0];
				5'h0B: cursor_end <= data_bus[4:0];
				5'h0C: start_address[13:8]<= data_bus[5:0];
				5'h0D: start_address[7:0] <= data_bus;
				5'h0E: cursor_adr[13:8]   <= data_bus[5:0];
				5'h0F: cursor_adr[7:0]    <= data_bus;
				5'h10: lightpen_adr[13:8] <= data_bus[5:0];
				5'h11: lightpen_adr[7:0]  <= data_bus;
				default: ;
			endcase
		else address_reg <= data_bus[4:0];
end

/**************************************************************************************************/

reg scanline_end;
reg last_row;

reg [7:0] hz_display_count;
reg [7:0] hz_syncpos_count;
reg [3:0] hz_pulsew_count;
reg [7:0] hz_total_count;

reg [6:0] vt_display_count;
reg [6:0] vt_syncpos_count;
reg [3:0] vt_pulsew_count;
reg [6:0] vt_total_count;
reg [4:0] vt_fraction_count;

always @ (negedge char_clk) begin
	if(scanline_end) scanline_end <= 0;
	else if(~|hz_total_count) scanline_end <= 1;
end

always @ (negedge char_clk) begin
	if(~nRESET) begin
		hz_total_count   <= 8'h00;
		hz_display_count <= 8'h00;
		hz_syncpos_count <= 8'h00;
		hz_pulsew_count  <= 4'h0;
	end else if(scanline_end) begin
		hz_total_count   <= horz_total;
		hz_display_count <= horz_display;
		hz_syncpos_count <= horz_syncpos;
		hz_pulsew_count  <= horz_pulsew;
	end else begin
		hz_total_count <= hz_total_count + 8'hff;
		if(|hz_display_count)
			hz_display_count <= hz_display_count + 8'hff;
		else if(|hz_syncpos_count)
			hz_syncpos_count <= hz_syncpos_count + 8'hff;
		else if(|hz_pulsew_count)
			hz_pulsew_count  <= hz_pulsew_count  + 4'hf;
	end
end

wire next_row = (char_scanline == max_scanline) & scanline_end;
wire screen_end = last_row & ~|vt_fraction_count & scanline_end; // finish last row

always @ (negedge char_clk) begin
	if(screen_end)	last_row <= 0;
	else if(~|vt_total_count & scanline_end) last_row <= 1;
end



always @ (negedge char_clk) begin
	if(~nRESET) begin
		vt_total_count   <= 7'h00;
		vt_display_count <= 7'h00;
		vt_syncpos_count <= 7'h00;
		vt_fraction_count<= 5'h00;
		vt_pulsew_count  <= 4'h0;
	end else if(screen_end) begin
		vt_total_count   <= vert_total;
		vt_display_count <= vert_display;
		vt_syncpos_count <= vert_syncpos;
		vt_fraction_count<= vert_fraction;
		vt_pulsew_count  <= vert_pulsew + 4'hf; // pulse from 1 to 16; 16 is 0 -> 15
	end else if(scanline_end) begin
		if(next_row) begin
			vt_total_count <= vt_total_count + 7'hff;
			if(|vt_display_count)
				vt_display_count <= vt_display_count + 7'hff;
			else if(|vt_syncpos_count)
				vt_syncpos_count <= vt_syncpos_count + 7'hff;
		end
		if(|vt_pulsew_count & v_sync) // pulse from 1 to 16
			vt_pulsew_count <= vt_pulsew_count + 4'hf;
		if(|vt_fraction_count & last_row)
			vt_fraction_count <= vt_fraction_count + 5'hff;

	end
end

/**************************************************************************************************/
// output assignment

reg [13:0] scanline_start_adr;

always @ (negedge char_clk) begin
	if(~nRESET) begin
		framestore_adr		<= 14'h0000;
		scanline_start_adr	<= 14'h0000;
	end else if(screen_end) begin
		framestore_adr		<= start_address;
		scanline_start_adr	<= start_address;
	end else if(next_row & |vt_display_count) begin
		framestore_adr		<= scanline_start_adr + horz_display;
		scanline_start_adr	<= scanline_start_adr + horz_display;
	end else if(scanline_end & |vt_display_count) begin
		framestore_adr		<= scanline_start_adr;
	end else begin
		framestore_adr		<= framestore_adr + 14'h0001;
	end
end

always @ (negedge char_clk) begin
	if(~nRESET|next_row|screen_end)	char_scanline <= 5'h00;
	else if(scanline_end)			char_scanline <= char_scanline + 5'h01;
end

always @ (*) display_en = nRESET & |hz_display_count & |vt_display_count;
always @ (*) cursor = nRESET & (framestore_adr == cursor_adr) & (char_scanline >= cursor_start) & (char_scanline <= cursor_end);

always @ (negedge char_clk) begin
	if(~nRESET) begin
		h_sync <= 0; v_sync <= 0;
	end else begin
		if(h_sync)
			h_sync <= |hz_pulsew_count[3:1];
		else
			h_sync <= ~|hz_syncpos_count & ~|hz_display_count & |hz_pulsew_count;

		if(scanline_end)
			v_sync <= ~|vt_syncpos_count & ~|vt_display_count & |vt_pulsew_count;
	end
end
endmodule // MC6845
