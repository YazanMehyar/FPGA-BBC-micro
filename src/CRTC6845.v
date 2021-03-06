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

	output HSYNC,
	output VSYNC,
	output reg DISEN,
	output reg CURSOR,
	output reg [13:0] FRAMESTORE_ADR,
	output reg [4:0]  ROW_ADDRESS
	);
	
	`ifdef SIMULATION
	// The registers will converge when implemented
	// This is used to aid with simulation (avoid 'x')
		initial begin
		FIELD        = 0;
		HORZ_COUNT   = 0;
		HPULSE_COUNT = 0;
		VERT_COUNT   = 0;
		VPULSE_COUNT = 0;
        H_STATE      = 0;
        V_STATE      = 0;
		VADJ_WAIT    = 0;
		VERT_ADJ_COUNT = 0;
		CURSOR_BLINK_COUNT = 6'h30;
		end
	`endif


/*********************************************************************************************/

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

/*********************************************************************************************/
//  Display enable
    reg [1:0] DISEN_SKEW;

    always @ (posedge CLK) 
        if(CRTC_en) begin
        	DISEN_SKEW <= {DISEN_SKEW[0],H_DISEN&V_DISEN};
        end

	always @ (*) casex(display_mode[5:4])
		2'b00: DISEN = H_DISEN&V_DISEN;
		2'b01: DISEN = DISEN_SKEW[0];
		2'b1x: DISEN = DISEN_SKEW[1];
	endcase

/*********************************************************************************************/
// Horizontal Sync

    wire       H_DISEN = H_STATE == `H_DISP;
    wire       NEWLINE = HORZ_COUNT == horz_total || H_RESET;
	assign	   HSYNC   = H_STATE == `H_PULSE;

    // Local wires / registers
    reg        H_RESET;
    reg  [1:0] H_STATE;
    reg  [7:0] HORZ_COUNT;
    reg  [3:0] HPULSE_COUNT;
    wire [7:0] nHORZ_COUNT = NEWLINE? 0 : HORZ_COUNT + 1;

    always @ (posedge CLK) if(CRTC_en) begin
        HORZ_COUNT <= nHORZ_COUNT;
        H_RESET    <= CRTC_WRITE&&A0&&reg_sel[4:2]==3'b000;
        
        if(NEWLINE) begin
        	H_STATE		 <= `H_DISP;
        	HPULSE_COUNT <= 0;
        end else case(H_STATE)
            `H_BACK:    if(NEWLINE) begin 
            				H_STATE 	 <= `H_DISP;
            				HPULSE_COUNT <= 0;
            			end
            				
            `H_PULSE:   if(HPULSE_COUNT==hv_sync[3:0]) begin
            				H_STATE 	 <= `H_BACK;
            			end else begin
            				HPULSE_COUNT <= HPULSE_COUNT + 1;
            			end
            				
            `H_FRONT:   if(nHORZ_COUNT==horz_syncpos) begin
            				H_STATE 	 <= hv_sync[3:0]!=0? `H_PULSE:`H_BACK;
            				HPULSE_COUNT <= HPULSE_COUNT + 1;
            			end
            			
            `H_DISP:    if(nHORZ_COUNT==horz_display) begin
            				H_STATE		 <= `H_FRONT;
            			end
        endcase
        
    end
/*********************************************************************************************/
// Vertical Sync
   
    wire       V_DISEN   = V_STATE == `V_DISP;
    wire       NEWvCHAR  = REND&NEWLINE;
    wire       NEWSCREEN = VEND&(NEWvCHAR&~nVADJ|VADJ&nVADJ&NEWLINE)||V_RESET;
	assign	   VSYNC	 = display_mode[0]&FSYNC? IVSYNC : V_STATE == `V_PULSE;

    // Local wires / registers
    reg		   V_RESET;
    reg  [1:0] V_STATE;
   	reg  [6:0] VERT_COUNT;
    reg  [4:0] VERT_ADJ_COUNT;
    reg  [3:0] VPULSE_COUNT;
    reg        VADJ_WAIT;
    reg		   FIELD;
    reg		   FSYNC;
    reg		   IVSYNC;
    wire [6:0] nVERT_COUNT = NEWSCREEN? 0 : VERT_COUNT + NEWvCHAR;
    wire       nVADJ       = |vert_total_adj;
    wire       VADJ        = VERT_ADJ_COUNT == vert_total_adj;
    wire       VEND        = VERT_COUNT     >= vert_total;
    wire       nV_FRONT    = nVERT_COUNT    == vert_display;
    
    always @ (posedge CLK) if(CRTC_en)
    	if(HORZ_COUNT==horz_total[7:1]) IVSYNC <= V_STATE == `V_PULSE;

    always @ (posedge CLK) if(NEWLINE&CRTC_en) begin 
        VERT_COUNT <= nVERT_COUNT;
        V_RESET    <= CRTC_WRITE&&A0&&reg_sel[4:2]==3'b001;
        
        if(NEWSCREEN) begin
        	V_STATE 	   <= `V_DISP;
			VPULSE_COUNT   <=  0;
			VERT_ADJ_COUNT <=  0;
			VADJ_WAIT	   <=  0;
			FSYNC		   <=  FIELD;
        end else case(V_STATE)
            `V_BACK:    if (VEND) begin
            				VERT_ADJ_COUNT <= VERT_ADJ_COUNT + (NEWvCHAR|VADJ_WAIT);
            				VADJ_WAIT	   <= NEWvCHAR;
            			end
            			
            `V_PULSE:   if(VPULSE_COUNT==hv_sync[7:4]) begin
            				V_STATE        <= `V_BACK;
            				FIELD 		   <= ~FIELD;
            			end else begin
            				VPULSE_COUNT   <= VPULSE_COUNT + 1;
            			end
            			
            `V_FRONT:   if(nVERT_COUNT==vert_syncpos) begin
            				V_STATE 	   <= `V_PULSE;
            				VPULSE_COUNT   <= VPULSE_COUNT + 1;
            			end
            			
            `V_DISP:    if(nVERT_COUNT==vert_display) begin
            				V_STATE <= `V_FRONT;
            			end
        endcase
        
    end

/*********************************************************************************************/
// RAM addressing
	reg [13:0] NEWLINE_ADR;
	wire       VISYNC   = &display_mode[1:0];
    wire       ODD_ROW  = VISYNC&FIELD;
    wire       REND     = ROW_ADDRESS[4:1]==max_scanline[4:1]
                          &&(VISYNC||ROW_ADDRESS[0]==max_scanline[0]);

	always @ (posedge CLK)
	if(~nRESET) begin
		FRAMESTORE_ADR <= 0;
		ROW_ADDRESS    <= 0;
	end else if(CRTC_en) begin
		if(NEWSCREEN) begin
			ROW_ADDRESS    <= ODD_ROW;
			FRAMESTORE_ADR <= start_adr;
			NEWLINE_ADR    <= start_adr;
		end else if(NEWvCHAR) begin
			NEWLINE_ADR    <= NEWLINE_ADR + horz_display;
			FRAMESTORE_ADR <= NEWLINE_ADR + horz_display;
			ROW_ADDRESS    <= ODD_ROW;
		end else if(NEWLINE) begin
			FRAMESTORE_ADR <= NEWLINE_ADR;
			ROW_ADDRESS    <= ROW_ADDRESS + (VISYNC? 2 : 1);
		end else begin
			FRAMESTORE_ADR <= FRAMESTORE_ADR + 1;
		end
    end


/*********************************************************************************************/
// Cursor position

	reg  [5:0] CURSOR_BLINK_COUNT;
	reg  [1:0] CURSOR_SKEW;
	reg        CURSOR_DISPLAY;
	
	wire       F_CURSOR  = FRAMESTORE_ADR == cursor_adr;
	wire       RS_CURSOR = ROW_ADDRESS    >= cursor_start_row;
	wire       RE_CURSOR = ROW_ADDRESS    <= cursor_end_row;
	wire       AT_CURSOR = CURSOR_DISPLAY&F_CURSOR&RS_CURSOR&RE_CURSOR;
	
	always @ (*) casex(display_mode[7:6]) 
		2'b00: CURSOR = AT_CURSOR;
		2'b01: CURSOR = CURSOR_SKEW[0];
		2'b1x: CURSOR = CURSOR_SKEW[1];
	endcase

	always @ (posedge CLK) if(CRTC_en) begin
		if(NEWSCREEN) begin
			CURSOR_BLINK_COUNT <= CURSOR_BLINK_COUNT + 1;
			case (cursor_blink_mode)
				2'b00: CURSOR_DISPLAY <= 1;
				2'b01: CURSOR_DISPLAY <= 0;
				2'b10: CURSOR_DISPLAY <= CURSOR_BLINK_COUNT[4];
				2'b11: CURSOR_DISPLAY <= CURSOR_BLINK_COUNT[5];
			endcase
		end
		CURSOR_SKEW <= {CURSOR_SKEW[0],AT_CURSOR};
	end

/*********************************************************************************************/

    always @ ( * ) begin
		case (DEBUG_SEL)
		4'h0: DEBUG_VAL = horz_total;
		4'h1: DEBUG_VAL = horz_syncpos;
		4'h2: DEBUG_VAL = horz_display;
		4'h3: DEBUG_VAL = max_scanline;
		4'h4: DEBUG_VAL = display_mode;
		4'h5: DEBUG_VAL = vert_total;
		4'h6: DEBUG_VAL = vert_syncpos;
		4'h7: DEBUG_VAL = vert_display;
		4'h8: DEBUG_VAL = V_STATE;
		4'h9: DEBUG_VAL = VERT_COUNT;		
		4'hA: DEBUG_VAL = VPULSE_COUNT;
		4'hB: DEBUG_VAL = start_adr;
		default:DEBUG_VAL = 8'h00;
		endcase

		case (DEBUG_SEL)
		4'h0: DEBUG_TAG = {`dlH,`dlZ,`dlT,`dlL};
		4'h1: DEBUG_TAG = {`dlH,`dlZ,`dlS,`dlP};
		4'h2: DEBUG_TAG = {`dlH,`dlZ,`dlD,`dlP};
		4'h3: DEBUG_TAG = {`dlM,`dlX,`dlS,`dlL};
		4'h4: DEBUG_TAG = {`dlD,`dlM,`dlO,`dlD};
		4'h5: DEBUG_TAG = {`dlV,`dlT,`dlT,`dlL};
		4'h6: DEBUG_TAG = {`dlV,`dlT,`dlS,`dlP};
		4'h7: DEBUG_TAG = {`dlV,`dlT,`dlD,`dlP};
		4'h8: DEBUG_TAG = {`dlV,`dlSP,`dlS,`dlT};
		4'h9: DEBUG_TAG = {`dlV,`dlC,`dlN,`dlT};
		4'hA: DEBUG_TAG = {`dlV,`dlP,`dlL,`dlC};
		4'hB: DEBUG_TAG = {`dlS,`dlT,`dlA,`dlD};
		default: DEBUG_TAG = {`dlN,`dlU,`dlL,`dlL};
		endcase
	end

endmodule
