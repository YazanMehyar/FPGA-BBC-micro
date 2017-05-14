`include "TOP.vh"

module TOP(
	input CLK100MHZ,
	input CPU_RESETN,

	input PS2_CLK,
	input PS2_DATA,

	output [3:0] VGA_R,
	output [3:0] VGA_G,
	output [3:0] VGA_B,
	output VGA_HS,
	output VGA_VS,

	output [1:0] LED,
	input  [3:0] SW, // [3] control break point, [2] disable interrupts
					 // [1] set break point, [0] display debugger
	input BTNU,
	input BTND,
	input BTNR,
	input BTNL,
	input BTNC,
	
	output AUD_SD,
	output AUD_PWM,

	inout [9:7] JC);

/*****************************************************************************/

	wire PIXELCLK;
	wire dRAM_en;	// d as in double ram
	wire RAM_en;
	wire PROC_en;
	wire hPROC_en;	// h as in half processor
	wire CRTCF_en;
	wire CRTCS_en;
	wire TTX_en;
	wire V_TURN;	// Video circuitry take control of ram reads

	Timing_Generator timer(
		.CLK100MHZ(CLK100MHZ),
		.PIXELCLK(PIXELCLK),
		.dRAM_en(dRAM_en),
		.RAM_en(RAM_en),
		.PROC_en(PROC_en),
		.CRTCS_en(CRTCS_en),
		.hPROC_en(hPROC_en),
		.CRTCF_en(CRTCF_en),
		.TTX_en(TTX_en),
		.V_TURN(V_TURN)
	);


/*****************************************************************************/
// MEMORY

	reg [7:0] RAM		[0:`KiB32];
	reg [7:0] BBCBASIC2 [0:`KiB16];
	reg [7:0] BBCOS12   [0:`KiB16];
	reg [7:0] DFS		[0:`KiB16];

	`ifdef SIMULATION
		`include "TEST_BBCOS12.vh"
		integer i;
		initial for(i = 0; i <= `KiB32; i = i + 1) RAM[i] = 0;
	`else
		`include "BBCOS12.vh"
	`endif

	`include "DFS.vh"
	`include "BBCBASIC2.vh"

	wire [15:0] pADDRESSBUS;
	wire [14:0] vADDRESSBUS;
	wire [13:0] FRAMESTORE_ADR;
	wire [4:0]  ROW_ADDRESS;

	wire [7:0] pDATABUS;
	wire [7:0] pDATA;
	wire [7:0] PORTA;
	wire [7:0] UPORTB;
	wire SYNC;
	wire usr_nIRQ;
	wire sys_nIRQ;
	wire TXT_MODE;

	wire RnW;
	wire nIRQ;
	wire COLUMN_MATCH;
	wire nBREAK_KEY;
	wire MOSI, MISO, SCK;
	wire SOUND;
	wire DISEN;
	wire [2:0] RGB;

	wire SHEILA		= &pADDRESSBUS[15:9] & ~pADDRESSBUS[8];
	wire OSBANKen	= &pADDRESSBUS[15:14] & ~SHEILA;
	wire AUXBANKen	= pADDRESSBUS[15] & ~pADDRESSBUS[14];

	reg [3:0] ROM_BANK;
	reg [7:0] ram_DATA;
	reg [7:0] rom_DATA;
	reg [7:0] vDATA;

	assign pDATABUS =  RnW&~SHEILA?		pDATA : 8'hzz;
	assign pDATA	=  pADDRESSBUS[15]? rom_DATA : ram_DATA;
	assign UPORTB	= {6'hzz,SCK,MOSI};
	assign nIRQ		= &{sys_nIRQ,usr_nIRQ};

//	Chip selects

	reg [9:0] nCSELECTS;
	always @ ( * ) begin
		if(SHEILA) casex(pADDRESSBUS[7:0])
		8'b0000_0xxx: nCSELECTS = 10'h3FE;
		8'b0000_1xxx: nCSELECTS = 10'h3FD;
		8'b0010_xxxx: nCSELECTS = 10'h3FB;
		8'b0011_xxxx: nCSELECTS = 10'h3F7;
		8'b010x_xxxx: nCSELECTS = 10'h3EF;
		8'b011x_xxxx: nCSELECTS = 10'h3DF;
		8'b100x_xxxx: nCSELECTS = 10'h3BF;
		8'b101x_xxxx: nCSELECTS = 10'h37F;
		8'b110x_xxxx: nCSELECTS = 10'h2FF;
		8'b111x_xxxx: nCSELECTS = 10'h1FF;
		default: nCSELECTS = 10'h3FF;
		endcase else nCSELECTS = 10'h3FF;
	end

	wire nCRTC		= nCSELECTS[0];
	wire nACIA		= nCSELECTS[1];
	wire nVIDPROC	= nCSELECTS[2] | RnW;
	wire nROMSEL 	= nCSELECTS[3] | RnW;

	wire nVIA		= nCSELECTS[4];
	wire nUVIA		= nCSELECTS[5];
	wire nFDC		= nCSELECTS[6];
	wire nADLC		= nCSELECTS[7];
	wire nADC 		= nCSELECTS[8];
	wire nTUBE		= nCSELECTS[9];
	wire SLOW_PROC = ~&{nVIA,nUVIA,nADC,nACIA,nCRTC};

/*****************************************************************************/
//	RAM & ROMS

	always @ ( posedge PIXELCLK )
		if(PROC_en&~nROMSEL) ROM_BANK <= pDATABUS[3:0];

	always @ ( posedge PIXELCLK )
		if(RAM_en)
			if(V_TURN)
				vDATA <= RAM[vADDRESSBUS];
			else if(RnW)
				ram_DATA <= RAM[pADDRESSBUS[14:0]];
			else if(~pADDRESSBUS[15])
				RAM[pADDRESSBUS[14:0]] <= pDATABUS;

	always @ ( posedge PIXELCLK )
		if(RAM_en)
			if(OSBANKen)
				rom_DATA <= BBCOS12[pADDRESSBUS[13:0]];
			else if(AUXBANKen)
				case(ROM_BANK)
				4'b0000: rom_DATA <= BBCBASIC2[pADDRESSBUS[13:0]];
				4'b0001: rom_DATA <= DFS[pADDRESSBUS[13:0]];
				endcase

/******************************************************************************/
// CRTC address correction

	reg [7:0] LS259_reg;
	wire LS259_D;
	wire [2:0] LS259_A;
	wire LS259en = nVIA & PROC_en;

	always @ ( posedge PIXELCLK )
		if(LS259en)	case (LS259_A)
			0:	LS259_reg[0] <= LS259_D;
			1:	LS259_reg[1] <= LS259_D;
			2:	LS259_reg[2] <= LS259_D;
			3:	LS259_reg[3] <= LS259_D;
			4:	LS259_reg[4] <= LS259_D;
			5:	LS259_reg[5] <= LS259_D;
			6:	LS259_reg[6] <= LS259_D;
			7:	LS259_reg[7] <= LS259_D;
		endcase

	wire B1 = ~&{LS259_reg[4],LS259_reg[5],FRAMESTORE_ADR[12]};
	wire B2 = ~&{B3,LS259_reg[5],FRAMESTORE_ADR[12]};
	wire B3 = ~&{LS259_reg[4],FRAMESTORE_ADR[12]};
	wire B4 = ~&{B3,FRAMESTORE_ADR[12]};

	wire [3:0] caa = FRAMESTORE_ADR[11:8] + {B4,B3,B2,B1} + 1'b1;
	assign vADDRESSBUS = TXT_MODE? {5'h1F,FRAMESTORE_ADR[9:0]}
						: {caa,FRAMESTORE_ADR[7:0],ROW_ADDRESS[2:0]};

/******************************************************************************/
// Test Helpers

	wire [15:0] PROC_val, DISP_val, SVIA_val, UVIA_val;
	wire [23:0] PROC_tag, DISP_tag, SVIA_tag, UVIA_tag;
	wire [3:0]  PROC_sel, DISP_sel, SVIA_sel, UVIA_sel;
	wire DEBUG_PIXEL;
	
	wire BTN_UP;
	wire BTN_DN;
	wire BTN_LT;
	wire BTN_RT;
	wire BTN_STEP;
	wire BTN_CONT;
	
	Edge_Trigger #(1) POS_BUTTON0(.clk(PIXELCLK),.IN(BTNR),.En(1'b1),.EDGE(BTN_RT));
	Edge_Trigger #(1) POS_BUTTON1(.clk(PIXELCLK),.IN(BTNL),.En(1'b1),.EDGE(BTN_LT));
	Edge_Trigger #(1) POS_BUTTON2(.clk(PIXELCLK),.IN(BTND),.En(1'b1),.EDGE(BTN_DN));
	Edge_Trigger #(1) POS_BUTTON3(.clk(PIXELCLK),.IN(BTNU),.En(1'b1),.EDGE(BTN_UP));
	Edge_Trigger #(1) BRKS_TRIG(.clk(PIXELCLK),.IN(BTNC&~SW[3]),.En(PROC_en),.EDGE(BTN_STEP));	
	Edge_Trigger #(1) BRKC_TRIG(.clk(PIXELCLK),.IN(BTNC&SW[3]), .En(PROC_en),.EDGE(BTN_CONT));
	
	reg  [15:0] BREAKPOINT;
	reg  [1:0]  BRK_STEP;
	reg         BRK_STOP;
	wire [23:0] BREAK_tag = {`dlB,`dlR,`dlK,`dlSP};
	wire [3:0]  BRK_INC = BTN_UP? 4'h1 : {4{BTN_DN}};
	
	always @ (posedge PIXELCLK)
		if(SW[3]) case(BRK_STEP)
			0: BREAKPOINT[3:0]   <= BREAKPOINT[3:0]   + BRK_INC;
			1: BREAKPOINT[7:4]   <= BREAKPOINT[7:4]   + BRK_INC;
			2: BREAKPOINT[11:8]  <= BREAKPOINT[11:8]  + BRK_INC;
			3: BREAKPOINT[15:12] <= BREAKPOINT[15:12] + BRK_INC;
		endcase

	always @ (posedge PIXELCLK)
		if(SW[3]) BRK_STEP <= BRK_STEP + (BTN_LT? 2'h1 : {2{BTN_RT}});
		
	always @ (posedge PIXELCLK)
		if(PROC_en)
			if(BRK_STOP) BRK_STOP <= ~BTN_CONT;
			else		 BRK_STOP <= SW[1]&(BREAKPOINT == pADDRESSBUS);
			
	wire BREAK = BRK_STOP & SYNC & ~BTN_STEP;
	
/******************************************************************************/

wire [1:0] PROC_VCC = 2'b11;
// Processor
	MOS6502 pocessor(
		.clk(PIXELCLK),
		.clk_en(SLOW_PROC? hPROC_en : PROC_en),
		.nRESET(CPU_RESETN&nBREAK_KEY),
		.SYNC(SYNC),
		.nIRQ(nIRQ|SW[2]),
		.nNMI(PROC_VCC[0]),
		.nSO(PROC_VCC[1]),
		.READY(~BREAK),
		.Data_bus(pDATABUS),
		.Address_bus(pADDRESSBUS),
		.RnW(RnW),
		.DEBUG_SEL(PROC_sel),
		.DEBUG_VAL(PROC_val),
		.DEBUG_TAG(PROC_tag)
	);

// Video control
	Display_Control dc(
		.PIXELCLK(PIXELCLK),
		.nRESET(CPU_RESETN),
		.dRAM_en(dRAM_en),
		.RAM_en(RAM_en),
		.PROC_en(PROC_en),
		.CRTCF_en(CRTCF_en),
		.CRTCS_en(CRTCS_en),
		.TTX_en(TTX_en),
		.nCS_CRTC(nCRTC),
		.nCS_VULA(nVIDPROC),
		.RnW(RnW),
		.A0(pADDRESSBUS[0]),
		.vDATABUS(vDATA),
		.pDATABUS(pDATABUS),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.TXT_MODE(TXT_MODE),
		.RGB(RGB),
		.FRAMESTORE_ADR(FRAMESTORE_ADR),
		.ROW_ADDRESS(ROW_ADDRESS),
		.DEBUG_SEL(DISP_sel),
		.DEBUG_VAL(DISP_val),
		.DEBUG_TAG(DISP_tag)
	);

wire [2:0] SYS_VCC = 3'b111;
wire [3:0] VCC_4   = 4'hF;
// System VIA
	MOS6522 #(`SYSVIA) sys_via(
		.clk(PIXELCLK),
		.clk_en(hPROC_en),
		.nRESET(CPU_RESETN),
		.CS1(SYS_VCC[0]),
		.nCS2(nVIA),
		.RnW(RnW),
		.RS(pADDRESSBUS[3:0]),
		.CA1(VGA_VS),
		.CA2(COLUMN_MATCH),
		.CB1(SYS_VCC[1]),
		.CB2(SYS_VCC[2]),
		.DATA(pDATABUS),
		.PORTA(PORTA),
		.PORTB({VCC_4,LS259_D,LS259_A}),
		.nIRQ(sys_nIRQ),
		.DEBUG_SEL(SVIA_sel),
		.DEBUG_VAL(SVIA_val),
		.DEBUG_TAG(SVIA_tag)
	);

wire [2:0] USR_VCC = 3'b111;
// User VIA
	MOS6522 #(`USRVIA) usr_via(
		.clk(PIXELCLK),
		.clk_en(hPROC_en),
		.nRESET(CPU_RESETN),
		.CS1(USR_VCC[0]),
		.nCS2(nUVIA),
		.RnW(RnW),
		.RS(pADDRESSBUS[3:0]),
		.CA1(USR_VCC[1]),
		.CA2(USR_VCC[2]),

		`ifdef SIMULATION
		// Iverilog issue
		.CB1(UPORTB[1]),
		`else
		.CB1(SCK),
		`endif

		.CB2(MISO),
		.DATA(pDATABUS),
		.PORTB(UPORTB),
		.nIRQ(usr_nIRQ),
		.DEBUG_SEL(UVIA_sel),
		.DEBUG_VAL(UVIA_val),
		.DEBUG_TAG(UVIA_tag)
	);

// Keyboard
	Keyboard keyboard(
		.clk(PIXELCLK),
		.clk_en(hPROC_en),
		.nRESET(CPU_RESETN),
		.autoscan(LS259_reg[3]),
		.column(PORTA[3:0]),
		.row(PORTA[6:4]),
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		.column_match(COLUMN_MATCH),
		.row_match(PORTA[7]),
		.nBREAK(nBREAK_KEY)
	);

// Sound
	Sound_Generator sound(
		.clk(PIXELCLK),
		.clk_en(PROC_en),
		.nWE(LS259_reg[0]),
		.DATA(PORTA),
		.PWM(SOUND)
	);

// Extra (MOCK) Peripherals
	Extra_Peripherals extra(
		.RnW(RnW),
		.nRESET(CPU_RESETN),
		.nFDC(nFDC),
		.nADC(nADC),
		.nTUBE(nTUBE),
		.nACIA(nACIA),
		.nADLC(nADLC),
		.DATABUS(pDATABUS)
	);

/**************************************************************************************************/
	assign AUD_SD  = 1'b1;				 // audio enable
	assign AUD_PWM = SOUND? 1'bz : 1'b0; // Pull up resistor by FPGA
	assign VGA_R = {4{(DEBUG_PIXEL&SW[0]) ^ RGB[0]}};
	assign VGA_G = {4{(DEBUG_PIXEL&SW[0]) ^ RGB[1]}};
	assign VGA_B = {4{(DEBUG_PIXEL&SW[0]) ^ RGB[2]}};
	assign LED[0] = 0;
	assign LED[1] = MISO;
	`ifdef SIMULATION
		// Iverilog Issue
		assign JC[7] = UPORTB[1];
		assign JC[8] = UPORTB[0];
	`else
		assign JC[7] = SCK;
		assign JC[8] = MOSI;
	`endif
	assign MISO = JC[9];

// TEST_ASSISTANCE

	Debug_Tool dtool(
		.PIXELCLK(PIXELCLK),
		.VSYNC(VGA_VS),
		.HSYNC(VGA_HS),
		.TAG1(PROC_tag),
		.VAL1(PROC_val),
		.SEL1(PROC_sel),
		.TAG2(DISP_tag),
		.VAL2(DISP_val),
		.SEL2(DISP_sel),
		.TAG3(SVIA_tag),
		.VAL3(SVIA_val),
		.SEL3(SVIA_sel),
		.TAG4(UVIA_tag),
		.VAL4(UVIA_val),
		.SEL4(UVIA_sel),
		.VALB(BREAKPOINT),
		.TAGB(BREAK_tag),
		.TOOL_B({2{~SW[3]}}&{BTN_LT,BTN_RT}),
		.PROBE_B({2{~SW[3]}}&{BTN_UP,BTN_DN}),
		.PIXEL_OUT(DEBUG_PIXEL)
	);


`ifdef SIMULATION

`endif

endmodule
