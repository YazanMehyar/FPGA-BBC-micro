`include "VIDEO.vh"

module Display_Control (
	input PIXELCLK,
	input nRESET,
	input dRAM_en,
	input RAM_en,
	input PROC_en,
	input hPROC_en,
	input PHI_2,
	input nCS_CRTC,
	input nCS_VULA,
	input RnW,
	input A0,

	input [7:0] vDATABUS,
	inout [7:0] pDATABUS,

	output VGA_HS,
	output VGA_VS,
	output RED,
	output GREEN,
	output BLUE,
	output reg [13:0] FRAMESTORE_ADR,
	output reg [4:0]  ROW_ADDRESS
	);

// Video Signal generator
	wire CRTC_en;
	wire HALF_SPEED;

// -- Horizontal Timing
	reg [1:0] H_STATE;
	reg [7:0] H_COUNTER;

	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) begin
			H_STATE   <= `H_DISPLAY;
			H_COUNTER <= 0;
		end else if(CRTC_en) begin
			H_COUNTER <= ~|H_COUNTER? HALF_SPEED? `H_COUNTER_INIT : {`H_COUNTER_INIT,1'b1}
									: H_COUNTER - 1;

			case (H_STATE)
				`H_BACK:   H_STATE <= ~|H_COUNTER?
								`H_DISPLAY :`H_BACK;
				`H_PULSE:  H_STATE <= H_COUNTER == (HALF_SPEED? `H_BACK_COUNT : {`H_BACK_COUNT,1'b0})?
								`H_BACK : `H_PULSE;
				`H_FRONT:  H_STATE <= H_COUNTER == (HALF_SPEED? `H_PULSE_COUNT: {`H_PULSE_COUNT,1'b0})?
								`H_PULSE : `H_FRONT;
				`H_DISPLAY:H_STATE <= H_COUNTER == (HALF_SPEED? `H_FRONT_COUNT: {`H_FRONT_COUNT,1'b0})?
								`H_FRONT : `H_DISPLAY;
				default: H_STATE <= 2'bxx;
			endcase
		end
	end

	wire NEWLINE  = H_COUNTER == 1;
	assign VGA_HS = H_STATE == `H_PULSE;

// -- Vertical Timing
	reg [1:0] V_STATE;
	reg [9:0] V_COUNTER;

	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) begin
			V_STATE   <= `V_DISPLAY;
			V_COUNTER <= `V_COUNTER_INIT;
		end else if(CRTC_en&NEWLINE) begin
			V_COUNTER <= ~|V_COUNTER? `V_COUNTER_INIT : V_COUNTER - 1;

			case (V_STATE)
				`V_BACK:   V_STATE <= ~|V_COUNTER? `V_DISPLAY :`V_BACK;
				`V_PULSE:  V_STATE <= V_COUNTER == `V_BACK_COUNT? `V_BACK : `V_PULSE;
				`V_FRONT:  V_STATE <= V_COUNTER == `V_PULSE_COUNT? `V_PULSE : `V_FRONT;
				`V_DISPLAY:V_STATE <= V_COUNTER == `V_FRONT_COUNT? `V_FRONT : `V_DISPLAY;
				default: V_STATE <= 2'bxx;
			endcase
		end
	end

	wire NEWSCREEN = ~|V_COUNTER & NEWLINE;
	wire VID_DISEN = V_STATE == `V_DISPLAY && H_STATE == `H_DISPLAY;
	assign VGA_VS  = V_STATE == `V_PULSE;

/****************************************************************************************/

// BBC Display Controller (CRTC)

	reg [13:0] start_adr;
	reg [13:0] cursor_adr;
	reg [3:0]  reg_sel;
	reg [7:0]  horz_display;
	reg [6:0]  vert_display;
	reg [4:0]  max_scanline;
	reg [4:0]  cursor_start_row;
	reg [4:0]  cursor_end_row;
	reg [1:0]  cursor_blink_mode;
	reg [1:0]  interlace_mode;

	// More registers can be included to meet more spec of the 6845 CRTC
	reg [7:0] pDATABUS_out;
	always_comb case (reg_sel[0])
		1'b0: pDATABUS_out = {2'b00,cursor_adr[13:8]};
		1'b1: pDATABUS_out = cursor_adr[7:0];
		default: pDATABUS_out = 8'hxx;
	endcase

	assign pDATABUS  = ~nCS_CRTC&PHI_2&RnW&nRESET? pDATABUS_out : 8'hzz;

	wire CRTC_WRITE = ~nCS_CRTC&~RnW&PROC_en;

	always @ (posedge PIXELCLK) begin
		if(CRTC_WRITE) begin
			if(A0) case (reg_sel)
				4'h1: horz_display   <= pDATABUS;
				4'h6: vert_display   <= pDATABUS[6:0];
				4'h8: interlace_mode <= pDATABUS[1:0];
				4'h9: max_scanline   <= pDATABUS[4:0];
				4'hA: begin
						cursor_blink_mode <= pDATABUS[6:5];
						cursor_start_row  <= pDATABUS[4:0];
					  end
				4'hB: cursor_end_row  <= pDATABUS[4:0];
				4'hC: start_adr[13:8] <= pDATABUS[5:0];
				4'hD: start_adr[7:0]  <= pDATABUS;
				4'hE: cursor_adr[13:8]<= pDATABUS[5:0];
				4'hF: cursor_adr[7:0] <= pDATABUS;
			endcase else reg_sel <= pDATABUS[4:0];
		end
	end

// -- BBC's display timing (NB MUST be a subset of the host)

	reg [7:0] HORZ_DISPLAY_COUNT;
	reg [6:0] VERT_DISPLAY_COUNT;
	reg H_END;

	wire INTERLACE_SYNC = interlace_mode == 2'b01;
	wire DISEN = VID_DISEN & ~H_END & |VERT_DISPLAY_COUNT;
	wire NEWvCHAR = ROW_ADDRESS == max_scanline && NEWLINE && (INTERLACE_SYNC? FIELD:1'b1);

	always @ (posedge PIXELCLK) begin
		if(~nRESET) begin
			HORZ_DISPLAY_COUNT <= horz_display;
			VERT_DISPLAY_COUNT <= vert_display;
			H_END <= 0;
		end else if(CRTC_en) begin
			if(NEWLINE)
				HORZ_DISPLAY_COUNT <= horz_display;
			else
				HORZ_DISPLAY_COUNT <= |HORZ_DISPLAY_COUNT? HORZ_DISPLAY_COUNT - 1 : 0;

			if(NEWSCREEN)
				VERT_DISPLAY_COUNT <= vert_display;
			else if(NEWvCHAR)
				VERT_DISPLAY_COUNT <= |VERT_DISPLAY_COUNT? VERT_DISPLAY_COUNT - 1 : 0;

			H_END <= ~|HORZ_DISPLAY_COUNT;
		end
	end

// -- RAM addressing

	// The RAM fails to catch up on the first full speed cycle
	reg [13:0] NEWLINE_ADR;
	reg FIELD;

	always @ (posedge PIXELCLK) begin
		if(~nRESET) begin
			FRAMESTORE_ADR <= 0;
			NEWLINE_ADR    <= 0;
		end else if(CRTC_en) begin
			if(NEWSCREEN) begin
				FRAMESTORE_ADR <= start_adr;
				NEWLINE_ADR    <= start_adr;
			end else if(NEWvCHAR) begin
				FRAMESTORE_ADR <= NEWLINE_ADR + horz_display;
				NEWLINE_ADR    <= NEWLINE_ADR + horz_display;
			end else if(NEWLINE) begin
				FRAMESTORE_ADR <= NEWLINE_ADR;
			end else begin
				FRAMESTORE_ADR <= FRAMESTORE_ADR + 1;
			end
		end
	end

	// Simulate interlace mode but progressively
	always @ (posedge PIXELCLK) begin
		if(~nRESET)	begin
			ROW_ADDRESS <= 0;
			FIELD <= 0;
		end else if(CRTC_en)
			if(NEWvCHAR | NEWSCREEN) begin
				ROW_ADDRESS <= 0;
				FIELD <= 0;
			end else if(NEWLINE) begin
				FIELD <= ~FIELD;
				if(interlace_mode == 2'b01)
					ROW_ADDRESS <= FIELD? ROW_ADDRESS + 1 : ROW_ADDRESS;
				else
					ROW_ADDRESS <= ROW_ADDRESS + 1;
			end
	end

// -- Cursor position

	reg [6:0] cursor_blink_count;
	reg cursor_display;
	wire AT_CURSOR = FRAMESTORE_ADR == cursor_adr
				&& ROW_ADDRESS >= cursor_start_row
				&& ROW_ADDRESS <= cursor_end_row
				&& DISEN
				&& cursor_display;

	always @ (posedge PIXELCLK) begin
		if(~nRESET) begin
			cursor_blink_count <= 0;
			cursor_display <= 0;
		end else if(NEWSCREEN&CRTC_en) begin
			cursor_blink_count <= cursor_blink_count + 1;
			case (cursor_blink_mode)
				2'b00: cursor_display <= 1;
				2'b01: cursor_display <= 0;
				2'b10: cursor_display <= cursor_blink_count[5];
				2'b11: cursor_display <= cursor_blink_count[6];
				default: cursor_display <= 1'bx;
			endcase
		end
	end

/****************************************************************************************/
// Video ULA

	reg [7:0] CONTROL;
	reg [7:0] SHIFTER;

	// Synthesizer has trouble with the following so it is broken down
	// reg [3:0] PALETTE [0:15];
	reg [3:0] PALETTE0,PALETTE1,PALETTE2,PALETTE3;
	reg [3:0] PALETTE4,PALETTE5,PALETTE6,PALETTE7;
	reg [3:0] PALETTE8,PALETTE9,PALETTEA,PALETTEB;
	reg [3:0] PALETTEC,PALETTED,PALETTEE,PALETTEF;

	assign CRTC_en    = CONTROL[4]? ~PROC_en&RAM_en : hPROC_en;
	assign HALF_SPEED = ~CONTROL[4];


// -- Shift speed

	reg SHIFT_en;
	always_comb case (CONTROL[3:2])
		2'b00: SHIFT_en = PROC_en;
		2'b01: SHIFT_en = RAM_en;
		2'b10: SHIFT_en = dRAM_en;
		2'b11: SHIFT_en = 1'b1;
		default: SHIFT_en = 1'bx;
	endcase

	always @ ( posedge PIXELCLK ) begin
		if(CRTC_en)			SHIFTER <= vDATABUS;
		else if(SHIFT_en)	SHIFTER <= {SHIFTER[6:0],1'b1};
	end

// -- uProcessor interface

	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) CONTROL <= 8'h00;
		else if(PROC_en&~nCS_VULA)
	 		if(A0)  case (pDATABUS[7:4])
	 			3'h0: PALETTE0 <= pDATABUS[3:0];	3'h1: PALETTE1 <= pDATABUS[3:0];
				3'h2: PALETTE2 <= pDATABUS[3:0];	3'h3: PALETTE3 <= pDATABUS[3:0];
				3'h4: PALETTE4 <= pDATABUS[3:0];	3'h5: PALETTE5 <= pDATABUS[3:0];
				3'h6: PALETTE6 <= pDATABUS[3:0];	3'h7: PALETTE7 <= pDATABUS[3:0];
				3'h8: PALETTE8 <= pDATABUS[3:0];	3'h9: PALETTE9 <= pDATABUS[3:0];
				3'hA: PALETTEA <= pDATABUS[3:0];	3'hB: PALETTEB <= pDATABUS[3:0];
				3'hC: PALETTEC <= pDATABUS[3:0];	3'hD: PALETTED <= pDATABUS[3:0];
				3'hE: PALETTEE <= pDATABUS[3:0];	3'hF: PALETTEF <= pDATABUS[3:0];
	 		endcase
			else	CONTROL <= pDATABUS;
	end

	reg PALETTE_COLOUR[3:0];
	always_comb begin
		case ({SHIFTER[7],SHIFTER[5],SHIFTER[3],SHIFTER[1]})
			3'h0: PALETTE_COLOUR = PALETTE0;	3'h1: PALETTE_COLOUR = PALETTE1;
			3'h2: PALETTE_COLOUR = PALETTE2;	3'h3: PALETTE_COLOUR = PALETTE3;
			3'h4: PALETTE_COLOUR = PALETTE4;	3'h5: PALETTE_COLOUR = PALETTE5;
			3'h6: PALETTE_COLOUR = PALETTE6;	3'h7: PALETTE_COLOUR = PALETTE7;
			3'h8: PALETTE_COLOUR = PALETTE8;	3'h9: PALETTE_COLOUR = PALETTE9;
			3'hA: PALETTE_COLOUR = PALETTEA;	3'hB: PALETTE_COLOUR = PALETTEB;
			3'hC: PALETTE_COLOUR = PALETTEC;	3'hD: PALETTE_COLOUR = PALETTED;
			3'hE: PALETTE_COLOUR = PALETTEE;	3'hF: PALETTE_COLOUR = PALETTEF;
			default: PALETTE_COLOUR <= 4'hx;
		endcase
	end

// -- Cursor drawing

	reg [2:0] CURSOR_seg;
	reg CURSOR_DRAW;

	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) CURSOR_seg <= 3'b000;
		else if(CRTC_en) begin
			if(AT_CURSOR)	CURSOR_seg <= 3'b001;
			else			CURSOR_seg <= CURSOR_seg << 1;

			CURSOR_DRAW <= AT_CURSOR&CONTROL[7]
							| CURSOR_seg[0]&CONTROL[6]
							| CURSOR_seg[1]&CONTROL[5]
							| CURSOR_seg[2]&CONTROL[5];
		end
	end

// -- Pixel colour
	wire VULA_DISEN = DISEN & ~ROW_ADDRESS[3];

	wire FLASH = ~(PALETTE_COLOUR[3]&CONTROL[0]);
	wire [2:0] PIXEL_COLOR = VULA_DISEN? FLASH? ~PALETTE_COLOUR[2:0] : PALETTE_COLOUR[2:0] : 3'b000;
	assign {BLUE,GREEN,RED} = CURSOR_DRAW? ~PIXEL_COLOR : PIXEL_COLOR;

endmodule
