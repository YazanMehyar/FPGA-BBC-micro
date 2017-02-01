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
				5'h0A:;
				5'h0B:;
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
// output assignment

reg [5:0] scanline_start;
reg [5:0] scanline_end;
reg [6:0] current_char_row;

always @ (negedge char_clk) begin
	if(~nRESET) begin
		framestore_adr <= 14'h0000;
		scanline_start <= 14'h0000;
	end else begin
		if(framestore_adr[7:0] == horz_total) begin // change to reflect +1
			if()
		end
	end
end

always @ (negedge char_clk) begin

end

always @ (negedge char_clk) begin

end

always @ (negedge char_clk) begin

end

always @ (negedge char_clk) begin

end

always @ (negedge char_clk) begin

end


endmodule // MC6845
