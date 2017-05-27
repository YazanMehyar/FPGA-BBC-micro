`include "VIDEO.vh"

module CRTC6845 (
	input [3:0] DEBUG_SEL,
	output reg [23:0] DEBUG_TAG,
	output reg [15:0] DEBUG_VAL,

	input CLK,
	input nRESET,
	input CRTC_en,
	input PROC_en,
	input nCS_CRTC,
	input RnW,
	input A0,
	
	inout [7:0] pDATABUS,

	output reg HSYNC,
	output reg VSYNC,
	output reg DISEN,
	output reg CURSOR,
	output [13:0] FRAMESTORE_ADR,
	output [4:0]  ROW_ADDRESS
	);
	
	`ifdef SIMULATION
	// The registers will converge when implemented
	// This is used to aid with simulation (avoid 'x')
		initial begin
		FIELD = 0;
		HORZ_COUNT = 0;
		HPULSE_COUNT = 0;
		HSYNC = 0;
		VERT_COUNT = 0;
		VPULSE_COUNT = 0;
		VSYNC = 0;
		rROW_ADR = 0;
		CURSOR_BLINK_COUNT = 0;
		end
	`endif


/**************************************************************************************************/

	reg [4:0]  reg_sel;
	reg [13:0] start_adr;
	reg [13:0] cursor_adr;
	reg [7:0]  hv_sync;
	reg [7:0]  horz_display;
	reg [7:0]  horz_syncpos;
	reg [7:0]  horz_total;
	reg [6:0]  vert_display;
	reg [6:0]  vert_syncpos;
	reg [6:0]  vert_total;
	reg [4:0]  vert_total_adj;
	reg [4:0]  max_scanline;
	reg [4:0]  cursor_start_row;
	reg [4:0]  cursor_end_row;
	reg [1:0]  cursor_blink_mode;
	reg [7:0]  display_mode;

	reg [7:0] pDATABUS_out;
	wire CRTC_WRITE  = ~nCS_CRTC&~RnW&PROC_en;
	assign pDATABUS  = ~nCS_CRTC&RnW&nRESET? pDATABUS_out : 8'hzz;
	
	always @ ( * ) case (reg_sel[0])
		1'b0: pDATABUS_out = {2'b00,cursor_adr[13:8]};
		1'b1: pDATABUS_out = cursor_adr[7:0];
		default: pDATABUS_out = 8'hxx;
	endcase

	always @ (posedge CLK)
		if(CRTC_WRITE) begin
			if(A0) case (reg_sel)
				5'h0: horz_total     <= pDATABUS;
				5'h1: horz_display   <= pDATABUS;
				5'h2: horz_syncpos   <= pDATABUS;
				5'h3: hv_sync        <= pDATABUS;
				5'h4: vert_total     <= pDATABUS[6:0];
				5'h5: vert_total_adj <= pDATABUS[4:0];
				5'h6: vert_display   <= pDATABUS[6:0];
				5'h7: vert_syncpos   <= pDATABUS[6:0];
				5'h8: display_mode	 <= pDATABUS;
				5'h9: max_scanline   <= pDATABUS[4:0];
				5'hA: begin
						cursor_blink_mode <= pDATABUS[6:5];
						cursor_start_row  <= pDATABUS[4:0];
					  end
				5'hB: cursor_end_row  <= pDATABUS[4:0];
				5'hC: start_adr[13:8] <= pDATABUS[5:0];
				5'hD: start_adr[7:0]  <= pDATABUS;
				5'hE: cursor_adr[13:8]<= pDATABUS[5:0];
				5'hF: cursor_adr[7:0] <= pDATABUS;
			endcase else reg_sel <= pDATABUS[4:0];
		end

/**************************************************************************************************/
	reg [7:0] HORZ_COUNT;
	reg [6:0] VERT_COUNT;
    reg [4:0] VERT_ADJ;
	reg [4:0] rROW_ADR;
    reg [3:0] HPULSE_COUNT;
    reg [4:0] VPULSE_COUNT;
	reg [1:0] DISEN_SKEW;
	reg [1:0] CURSOR_SKEW;
	reg hDISEN;
	reg vDISEN;
	reg FIELD;
    reg ADJ_STATE;
	
	wire [4:0] NEXT_ROW;
    wire ODD_ROW = ~INTERLACE_SYNC&FIELD;
    wire HEND    = HORZ_COUNT==horz_total;
    wire VEND    = VERT_COUNT==vert_total;
    wire REND    = ODD_ROW?rROW_ADR[4:1]==max_scanline[4:1]:rROW_ADR==max_scanline;

	wire INTERLACE_SYNC = ~&display_mode[1:0];
	wire NEWLINE   = HEND&CRTC_en;
	wire NEWvCHAR  = REND&NEWLINE;
	wire NEWSCREEN = VEND&(|vert_total_adj? ~|VERT_ADJ&NEWLINE:NEWvCHAR);
	
	always @ (*) casex(display_mode[5:4])
		2'b00: DISEN = vDISEN & hDISEN;
		2'b01: DISEN = DISEN_SKEW[0];
		2'b1x: DISEN = DISEN_SKEW[1];
	endcase
	
    always @ (posedge CLK) `ifdef SIMULATION if(nRESET) `endif begin
        if(HORZ_COUNT==horz_syncpos) HSYNC <= |HPULSE_COUNT;
        else if(HSYNC)               HSYNC <= |HPULSE_COUNT;

        if(VERT_COUNT==vert_syncpos) VSYNC <= |VPULSE_COUNT;
        else if(VSYNC)               VSYNC <= |VPULSE_COUNT;

        if(NEWLINE)       HPULSE_COUNT <= hv_sync[3:0];
        else if(CRTC_en)  HPULSE_COUNT <= HPULSE_COUNT - HSYNC;

        if(NEWSCREEN)     VPULSE_COUNT <= ~|hv_sync[7:4]? 5'h10:hv_sync;
        else if(NEWLINE)  VPULSE_COUNT <= VPULSE_COUNT - VSYNC;

		if(NEWLINE)		  HORZ_COUNT <= 0;
		else if(CRTC_en)  HORZ_COUNT <= HORZ_COUNT + (HEND? 0:1);
		
		if(NEWSCREEN)	  VERT_COUNT <= 0;
		else if(NEWvCHAR) VERT_COUNT <= VERT_COUNT + (VEND? 0:1);

		// Vertical total adjust (additional scanlines in vertical backporch)
        if(NEWSCREEN)     VERT_ADJ <= vert_total_adj;
        else if(NEWLINE)  VERT_ADJ <= VERT_ADJ - (VEND&NEWvCHAR|ADJ_STATE);

        if(NEWSCREEN)     ADJ_STATE <= 0;
        else if(NEWvCHAR) ADJ_STATE <= VEND;
		
		// Display enable character skew
		if(CRTC_en) DISEN_SKEW <= {DISEN_SKEW[0],vDISEN&hDISEN};
				
		// Horizontal display enable and vertical display enable
		if(NEWSCREEN|NEWLINE)
			hDISEN <= 1;
		else if(HORZ_COUNT==horz_display)
			hDISEN <= 0;
	
		if(NEWSCREEN)
			vDISEN <= 1;
		else if(VERT_COUNT==vert_display)
			vDISEN <= 0;

        if(NEWSCREEN) FIELD <= ~FIELD;
    end
			
/**************************************************************************************************/
// -- RAM addressing

	reg [13:0] NEWLINE_ADR;
	reg [13:0] rFRAMESTORE_ADR;
	reg [13:0] NEWCHAR_ADR;
	
	assign NEXT_ROW = rROW_ADR + (INTERLACE_SYNC? 1 : 2);
	always @ (posedge CLK) begin
		if(CRTC_en) begin
			rFRAMESTORE_ADR <= FRAMESTORE_ADR + 1;
			if(NEWSCREEN|NEWvCHAR) begin
				NEWLINE_ADR <= FRAMESTORE_ADR;
				NEWCHAR_ADR <= FRAMESTORE_ADR + horz_display;
			end
		end

		if(NEWSCREEN|NEWvCHAR)
			rROW_ADR <= 0;
        else if(NEWLINE)
            rROW_ADR <= NEXT_ROW;
    end
	
	assign FRAMESTORE_ADR = NEWSCREEN? start_adr   : 
							NEWvCHAR?  NEWCHAR_ADR :  
							NEWLINE?   NEWLINE_ADR : rFRAMESTORE_ADR;
							
	assign ROW_ADDRESS = NEWvCHAR|NEWSCREEN? ODD_ROW :
						 NEWLINE?     {NEXT_ROW[4:1],ODD_ROW?1'b1:NEXT_ROW[0]} 
                                    : {rROW_ADR[4:1],ODD_ROW?1'b1:rROW_ADR[0]};


// -- Cursor position
	reg [5:0] CURSOR_BLINK_COUNT;
	reg CURSOR_DISPLAY;
	wire F_CURSOR  = FRAMESTORE_ADR == cursor_adr;
	wire RS_CURSOR = ROW_ADDRESS >= cursor_start_row;
	wire RE_CURSOR = ROW_ADDRESS <= cursor_end_row;
	wire AT_CURSOR = DISEN&CURSOR_DISPLAY&F_CURSOR&RS_CURSOR&RE_CURSOR;
	
	always @ (*) casex(display_mode[7:6]) 
		2'b00: CURSOR = AT_CURSOR;
		2'b01: CURSOR = CURSOR_SKEW[0];
		2'b1x: CURSOR = CURSOR_SKEW[1];
	endcase

	always @ (posedge CLK) begin
		if(NEWSCREEN) begin
			CURSOR_BLINK_COUNT <= CURSOR_BLINK_COUNT + 1;
			case (cursor_blink_mode)
				2'b00: CURSOR_DISPLAY <= 1;
				2'b01: CURSOR_DISPLAY <= 0;
				2'b10: CURSOR_DISPLAY <= CURSOR_BLINK_COUNT[4];
				2'b11: CURSOR_DISPLAY <= CURSOR_BLINK_COUNT[5];
			endcase
		end
		
		if(CRTC_en) CURSOR_SKEW <= {CURSOR_SKEW[0],AT_CURSOR};
	end

/**************************************************************************************************/

	always @ ( * ) begin
		case (DEBUG_SEL)
		4'h0: DEBUG_VAL = start_adr;
		4'h1: DEBUG_VAL = horz_display;
		4'h2: DEBUG_VAL = vert_display;
		4'h3: DEBUG_VAL = max_scanline;
		4'h4: DEBUG_VAL = display_mode;
		4'h5: DEBUG_VAL = cursor_adr;
		default:DEBUG_VAL = 8'h00;
		endcase

		case (DEBUG_SEL)
		4'h0: DEBUG_TAG = {`dlS,`dlT,`dlA,`dlD};
		4'h1: DEBUG_TAG = {`dlH,`dlZ,`dlD,`dlP};
		4'h2: DEBUG_TAG = {`dlV,`dlT,`dlD,`dlP};
		4'h3: DEBUG_TAG = {`dlM,`dlX,`dlS,`dlL};
		4'h4: DEBUG_TAG = {`dlI,`dlN,`dlT,`dlM};
		4'h5: DEBUG_TAG = {`dlC,`dlS,`dlA,`dlD};
		default: DEBUG_TAG = {`dlN,`dlU,`dlL,`dlL};
		endcase
	end

endmodule
