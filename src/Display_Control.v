`include "VIDEO.vh"

module Display_Control (
	input [3:0] DEBUG_SEL,
	output reg [23:0] DEBUG_TAG,
	output reg [15:0] DEBUG_VAL,

	input CLK,
	input nRESET,
	input CLK_16en,
	input CLK_8en,
	input CLK_6en,
	input CLK_4en,
	input CLK_2en,
	input CLK_1en,
	input CLK_2ven,
	input PROC_en,
	input nCS_CRTC,
	input nCS_VULA,
	input RnW,
	input A0,

	input [7:0] vDATABUS,
	inout [7:0] pDATABUS,

	output HSYNC,
	output VSYNC,
	output TXT_MODE,
	output [2:0]  RGB,
	output [13:0] FRAMESTORE_ADR,
	output [4:0]  ROW_ADDRESS
	);

// Video Signal generator

/**************************************************************************************************/
// BBC Display Controller (CRTC MC6845)

	wire CRTC_en;
	wire CURSOR;
	wire wDISEN;
	wire [23:0] CRTC_DEBUG_TAG;
	wire [15:0] CRTC_DEBUG_VAL;
	
	reg DISEN;
	always @ (posedge CLK) if(CRTC_en) DISEN <= wDISEN;

	CRTC6845 crtc(
	.DEBUG_SEL(DEBUG_SEL),
	.DEBUG_TAG(CRTC_DEBUG_TAG),
	.DEBUG_VAL(CRTC_DEBUG_VAL),

	.CLK(CLK),
	.nRESET(nRESET),
	.CRTC_en(CRTC_en),
	.PROC_en(PROC_en),
	.nCS_CRTC(nCS_CRTC),
	.RnW(RnW),
	.A0(A0),
	
	.pDATABUS(pDATABUS),

	.HSYNC(HSYNC),
	.VSYNC(VSYNC),
	.DISEN(wDISEN),
	.CURSOR(CURSOR),
	.FRAMESTORE_ADR(FRAMESTORE_ADR),
	.ROW_ADDRESS(ROW_ADDRESS));
	
/**************************************************************************************************/
// BBC Teletext chip (SA5050)

	wire [2:0] SA_RGB;
	reg  [6:0] SA_DATA;
	
	always @ (posedge CLK) if(CLK_1en) SA_DATA  <= vDATABUS[6:0];

    TELETEXT_5050 teletext (
    .CLK(CLK),
    .SA_F1(CLK_1en),
    .SA_T6(CLK_6en),
    .VSYNC(VSYNC),
    .HSYNC(HSYNC),
    .LOSE(DISEN),
    .DATABUS(SA_DATA),
    .RGB(SA_RGB));

/**************************************************************************************************/
// Video ULA
	
	reg [7:0] CONTROL;
	reg [7:0] SHIFTER;
	reg [3:0] CURSOR_seg;
	reg SHIFT_en;
	wire CURSOR_DRAW;

	assign CRTC_en  = CONTROL[4]? CLK_2ven : CLK_1en;
	assign TXT_MODE = CONTROL[1];
	
	// Synthesizer has trouble with the following so it is broken down
	// reg [3:0] PALETTE [0:15];
	reg [3:0] PALETTE0,PALETTE1,PALETTE2,PALETTE3;
	reg [3:0] PALETTE4,PALETTE5,PALETTE6,PALETTE7;
	reg [3:0] PALETTE8,PALETTE9,PALETTEA,PALETTEB;
	reg [3:0] PALETTEC,PALETTED,PALETTEE,PALETTEF;


	always @ ( * ) case (CONTROL[3:2])
		2'b00: SHIFT_en = CLK_2en;
		2'b01: SHIFT_en = CLK_4en;
		2'b10: SHIFT_en = CLK_8en;
		2'b11: SHIFT_en = CLK_16en;
	endcase

	always @ (posedge CLK)
		if(CRTC_en)			SHIFTER <= vDATABUS;
		else if(SHIFT_en)	SHIFTER <= {SHIFTER[6:0],1'b1};


	always @ (posedge CLK) if(CRTC_en) begin
		if(CURSOR)		
			if(CONTROL[1])	CURSOR_seg <= DISEN;
			else			CURSOR_seg <= wDISEN;
		else			CURSOR_seg <= CURSOR_seg << 1;
	end
		
	assign CURSOR_DRAW = CONTROL[7]&CURSOR_seg[0]
						|CONTROL[6]&CURSOR_seg[1]
						|CONTROL[5]&CURSOR_seg[2]
						|CONTROL[5]&CURSOR_seg[3];

    // -- uProcessor interface
	always @ ( posedge CLK)
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

	reg [3:0] PALETTE_COLOUR;
	always @ ( * ) case ({SHIFTER[7],SHIFTER[5],SHIFTER[3],SHIFTER[1]})
		4'h0: PALETTE_COLOUR = PALETTE0;	4'h1: PALETTE_COLOUR = PALETTE1;
		4'h2: PALETTE_COLOUR = PALETTE2;	4'h3: PALETTE_COLOUR = PALETTE3;
		4'h4: PALETTE_COLOUR = PALETTE4;	4'h5: PALETTE_COLOUR = PALETTE5;
		4'h6: PALETTE_COLOUR = PALETTE6;	4'h7: PALETTE_COLOUR = PALETTE7;
		4'h8: PALETTE_COLOUR = PALETTE8;	4'h9: PALETTE_COLOUR = PALETTE9;
		4'hA: PALETTE_COLOUR = PALETTEA;	4'hB: PALETTE_COLOUR = PALETTEB;
		4'hC: PALETTE_COLOUR = PALETTEC;	4'hD: PALETTE_COLOUR = PALETTED;
		4'hE: PALETTE_COLOUR = PALETTEE;	4'hF: PALETTE_COLOUR = PALETTEF;
	endcase

	wire VULA_DISEN = DISEN&~ROW_ADDRESS[3];
	wire FLASH = ~(PALETTE_COLOUR[3]&CONTROL[0]);
	wire [2:0] PIXEL_COLOR = CONTROL[1]? SA_RGB : VULA_DISEN? (FLASH?~PALETTE_COLOUR[2:0]:PALETTE_COLOUR[2:0]) : 3'b000;
	assign RGB = CURSOR_DRAW? ~PIXEL_COLOR : PIXEL_COLOR;

/**************************************************************************************************/

	reg [23:0] VULA_DEBUG_TAG;
	reg [15:0] VULA_DEBUG_VAL;
	
	always @ ( * ) begin
		case (DEBUG_SEL)
			4'hF: 	VULA_DEBUG_VAL = CONTROL;
			default:VULA_DEBUG_VAL = 8'h00;
		endcase

		case (DEBUG_SEL)
			4'hF: 	 VULA_DEBUG_TAG = {`dlC,`dlT,`dlR,`dlL};
			default: VULA_DEBUG_TAG = {`dlN,`dlU,`dlL,`dlL};
		endcase
	end

	always @ ( * ) begin
		case (DEBUG_SEL)
		4'hF:	 DEBUG_VAL = VULA_DEBUG_VAL;
		default: DEBUG_VAL = CRTC_DEBUG_VAL;
		endcase

		case (DEBUG_SEL)
		4'hF:	 DEBUG_TAG = VULA_DEBUG_TAG;
		default: DEBUG_TAG = CRTC_DEBUG_TAG;
		endcase
	end

endmodule
