`include "VIDEO.vh"

module Display_Control (
	input [3:0] DEBUG_SEL,
	output reg [23:0] DEBUG_TAG,
	output reg [15:0] DEBUG_VAL,

	input PIXELCLK,
	input nRESET,
	input dRAM_en,
	input RAM_en,
	input PROC_en,
	input CRTCF_en,
	input CRTCS_en,
	input TTX_en,
	input nCS_CRTC,
	input nCS_VULA,
	input RnW,
	input A0,

	input [7:0] vDATABUS,
	inout [7:0] pDATABUS,

	output VGA_HS,
	output VGA_VS,
	output TXT_MODE,
	output [2:0] RGB,
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
	always @ ( * ) case (reg_sel[0])
		1'b0: pDATABUS_out = {2'b00,cursor_adr[13:8]};
		1'b1: pDATABUS_out = cursor_adr[7:0];
		default: pDATABUS_out = 8'hxx;
	endcase

	assign pDATABUS  = ~nCS_CRTC&RnW&nRESET? pDATABUS_out : 8'hzz;

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

	wire INTERLACE_SYNC = ~&interlace_mode;
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
			else if(|HORZ_DISPLAY_COUNT)
				HORZ_DISPLAY_COUNT <= HORZ_DISPLAY_COUNT - 1;

			if(NEWSCREEN)
				VERT_DISPLAY_COUNT <= vert_display;
			else if(NEWvCHAR & |VERT_DISPLAY_COUNT)
				VERT_DISPLAY_COUNT <= VERT_DISPLAY_COUNT - 1;

			H_END <= ~|HORZ_DISPLAY_COUNT;
		end
	end

// -- RAM addressing

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
		if(CRTC_en)
			if(NEWvCHAR | NEWSCREEN) begin
				ROW_ADDRESS <= 0;
				FIELD <= 0;
			end else if(NEWLINE) begin
				FIELD <= ~FIELD;
				if(INTERLACE_SYNC)
					ROW_ADDRESS <= ROW_ADDRESS + FIELD;
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
// SA5050 Teletext
	wire SA_F1 = CRTC_en;
	wire SA_T6 = TTX_en;
	wire [5:0] SA_dots;
	reg  [6:0] SA_code;
	reg  [3:0] SA_row;
	reg  [5:0] SA_shifter;
	reg  SA_DISEN;
	
	SA_ROM char_rom(.code(SA_code),.line(SA_row),.pattern(SA_dots));

	always @ (posedge PIXELCLK) begin
		if(SA_F1) begin
			SA_code <= vDATABUS[6:0];
			SA_shifter <= SA_dots;
			SA_DISEN <= DISEN;
		end else if(SA_T6) begin
			SA_shifter <= SA_shifter << 1;
		end
	end
	
	always @ (posedge PIXELCLK) 
		if(SA_F1) begin
			if(NEWSCREEN)	SA_row <= 0;
			else if(NEWLINE)SA_row <= (SA_row == 9)? 0 : SA_row + FIELD;
		end
	
	wire[2:0] SA_BGR = SA_DISEN? {3{SA_shifter[5]}} : 3'b000;
	assign TXT_MODE = CONTROL[1];


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

	assign CRTC_en    = CONTROL[4]? RAM_en&~CRTCF_en : CRTCS_en;
	assign HALF_SPEED = ~CONTROL[4];


// -- Shift speed

	reg SHIFT_en;
	always @ ( * ) begin
		case (CONTROL[3:2])
			2'b00: SHIFT_en = CRTCF_en;
			2'b01: SHIFT_en = RAM_en;
			2'b10: SHIFT_en = dRAM_en;
			2'b11: SHIFT_en = 1'b1;
			default: SHIFT_en = 1'bx;
		endcase
	end

	always @ ( posedge PIXELCLK ) begin
		if(CRTC_en)			SHIFTER <= vDATABUS;
		else if(SHIFT_en)	SHIFTER <= {SHIFTER[6:0],1'b1};
	end

// -- uProcessor interface

	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) CONTROL <= 8'h00;
		else if(PROC_en&~nCS_VULA)
	 		if(A0)  case (pDATABUS[7:4])
	 			4'h0: PALETTE0 <= pDATABUS[3:0];	4'h1: PALETTE1 <= pDATABUS[3:0];
				4'h2: PALETTE2 <= pDATABUS[3:0];	4'h3: PALETTE3 <= pDATABUS[3:0];
				4'h4: PALETTE4 <= pDATABUS[3:0];	4'h5: PALETTE5 <= pDATABUS[3:0];
				4'h6: PALETTE6 <= pDATABUS[3:0];	4'h7: PALETTE7 <= pDATABUS[3:0];
				4'h8: PALETTE8 <= pDATABUS[3:0];	4'h9: PALETTE9 <= pDATABUS[3:0];
				4'hA: PALETTEA <= pDATABUS[3:0];	4'hB: PALETTEB <= pDATABUS[3:0];
				4'hC: PALETTEC <= pDATABUS[3:0];	4'hD: PALETTED <= pDATABUS[3:0];
				4'hE: PALETTEE <= pDATABUS[3:0];	4'hF: PALETTEF <= pDATABUS[3:0];
	 		endcase else CONTROL <= pDATABUS;
	end

	reg [3:0] PALETTE_COLOUR;
	always @ ( * ) begin
		case ({SHIFTER[7],SHIFTER[5],SHIFTER[3],SHIFTER[1]})
			4'h0: PALETTE_COLOUR = PALETTE0;	4'h1: PALETTE_COLOUR = PALETTE1;
			4'h2: PALETTE_COLOUR = PALETTE2;	4'h3: PALETTE_COLOUR = PALETTE3;
			4'h4: PALETTE_COLOUR = PALETTE4;	4'h5: PALETTE_COLOUR = PALETTE5;
			4'h6: PALETTE_COLOUR = PALETTE6;	4'h7: PALETTE_COLOUR = PALETTE7;
			4'h8: PALETTE_COLOUR = PALETTE8;	4'h9: PALETTE_COLOUR = PALETTE9;
			4'hA: PALETTE_COLOUR = PALETTEA;	4'hB: PALETTE_COLOUR = PALETTEB;
			4'hC: PALETTE_COLOUR = PALETTEC;	4'hD: PALETTE_COLOUR = PALETTED;
			4'hE: PALETTE_COLOUR = PALETTEE;	4'hF: PALETTE_COLOUR = PALETTEF;
			default: PALETTE_COLOUR = 4'hx;
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
    wire [2:0] VDU_COLOUR = PALETTE_COLOUR[2:0];
// -- Pixel colour
	wire VULA_DISEN = DISEN & (~ROW_ADDRESS[3]|CONTROL[1]);
	wire FLASH = ~(PALETTE_COLOUR[3]&CONTROL[0]);
	wire [2:0] PIXEL_COLOR = VULA_DISEN? FLASH? ~VDU_COLOUR : VDU_COLOUR : 3'b000;
    wire [2:0] BGR = CONTROL[1]? SA_BGR : PIXEL_COLOR;
	assign RGB = CURSOR_DRAW? ~BGR : BGR;

/****************************************************************************************/

	always @ ( * ) begin
		case (DEBUG_SEL)
		4'h0: DEBUG_VAL = start_adr;
		4'h1: DEBUG_VAL = horz_display;
		4'h2: DEBUG_VAL = vert_display;
		4'h3: DEBUG_VAL = max_scanline;
		4'h4: DEBUG_VAL = interlace_mode;
		4'h5: DEBUG_VAL = cursor_adr;
		4'h6: DEBUG_VAL = CONTROL;
		4'h8: DEBUG_VAL = PALETTE4;
		4'h9: DEBUG_VAL = PALETTE5;
		4'hA: DEBUG_VAL = PALETTE6;
		4'hB: DEBUG_VAL = PALETTE7;
		4'hC: DEBUG_VAL = PALETTE8;
		4'hD: DEBUG_VAL = PALETTE9;
		4'hE: DEBUG_VAL = PALETTEA;
		4'hF: DEBUG_VAL = PALETTEB;
		default:DEBUG_VAL = 8'h00;
		endcase

		case (DEBUG_SEL)
		4'h0: DEBUG_TAG = {`dlS,`dlT,`dlA,`dlD};
		4'h1: DEBUG_TAG = {`dlH,`dlZ,`dlD,`dlP};
		4'h2: DEBUG_TAG = {`dlV,`dlT,`dlD,`dlP};
		4'h3: DEBUG_TAG = {`dlM,`dlX,`dlS,`dlL};
		4'h4: DEBUG_TAG = {`dlI,`dlN,`dlT,`dlM};
		4'h5: DEBUG_TAG = {`dlC,`dlS,`dlA,`dlD};
		4'h6: DEBUG_TAG = {`dlC,`dlT,`dlR,`dlL};
		4'h8: DEBUG_TAG = {`dlP,`dlA,`dlL,`dl4};
		4'h9: DEBUG_TAG = {`dlP,`dlA,`dlL,`dl5};
		4'hA: DEBUG_TAG = {`dlP,`dlA,`dlL,`dl6};
		4'hB: DEBUG_TAG = {`dlP,`dlA,`dlL,`dl7};
		4'hC: DEBUG_TAG = {`dlP,`dlA,`dlL,`dl8};
		4'hD: DEBUG_TAG = {`dlP,`dlA,`dlL,`dl9};
		4'hE: DEBUG_TAG = {`dlP,`dlA,`dlL,`dlA};
		4'hF: DEBUG_TAG = {`dlP,`dlA,`dlL,`dlB};
		default: DEBUG_TAG = {`dlN,`dlU,`dlL,`dlL};
		endcase
	end

/****************************************************************************************/

endmodule
