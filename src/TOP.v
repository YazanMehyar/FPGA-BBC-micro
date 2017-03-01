module TOP(
	input CLK100MHZ,
	input PS2_CLK,
	input PS2_DATA,
	input CPU_RESETN,

	output [3:0] VGA_R,
	output [3:0] VGA_G,
	output [3:0] VGA_B,
	output VGA_HS,
	output VGA_VS
	);

	`define KiB16 16383
	`define KiB32 32767

	wire VCC   = 1'b1;
	wire VCC_4 = 4'hF;
	wire GND   = 1'b0;

/*****************************************************************************/

	wire [15:0] pADDRESSBUS;
	wire [13:0] cFRAMESTORE;
	wire [4:0] cROWADDRESS;

	wire CLK_PROC, CLK_RAM, CLK_CRTC, CLK_hPROC;
	wire cDISPLAYen, CURSOR, DISEN;
	wire VGA_HSYNC, VGA_VSYNC;
	wire PHI_2, RnW, nIRQ;
	wire [7:0] PORTA, COL_MATCH;
	wire RED, GREEN, BLUE;

/*****************************************************************************/

	assign VGA_R = {4{RED}};
	assign VGA_G = {4{GREEN}};
	assign VGA_B = {4{BLUE}};

/*****************************************************************************/
// PIXEL RATE @ 25.17 MHz (~25MHz)

	wire PIXELCLK = PIXELDIVIDER[1];
	reg [1:0] PIXELDIVIDER = 0;
	always @ (posedge CLK100MHZ) PIXELDIVIDER <= PIXELDIVIDER + 1;

	// RESET on startup
	reg [4:0] RESET_COUNTER = 5'h1F;
	always @ (posedge PIXELCLK) begin
		if(~CPU_RESETN)
			RESET_COUNTER <= 5'h1F;
		else if(|RESET_COUNTER)
			RESET_COUNTER <= RESET_COUNTER + 5'h1F;
	end

	wire nMASTER_RESET = ~|RESET_COUNTER & CPU_RESETN;

/****************************************************************************/
// MEMORY

	`include "BBCOS12.vh"
	`include "BBCBASIC2.vh"

	// ROM Bank Select
	reg [3:0] ROM_BANK;
	always @ ( posedge CLK_PROC ) begin
		if(~nROMSEL) ROM_BANK <= DATABUS[3:0];
	end

	// ROM
	wire OSBANKen 	 = &pADDRESSBUS[15:14] & ~SHEILA;
	wire BASICBANKen = pADDRESSBUS[15] & ~pADDRESSBUS[14] & ~|ROM_BANK;

	reg [7:0] RAM [0:`KiB32];
	reg [7:0] vDATA;
	reg [7:0] pDATA;
	wire [7:0] DATABUS = RnW&~SHEILA? pDATA:8'hzz;
	wire [14:0] vADDRESSBUS;

	always @ ( negedge CLK_RAM ) begin
		if(PHI_2 & pADDRESSBUS[15]) begin
			if(OSBANKen) 		pDATA <= BBCOS12[pADDRESSBUS[13:0]];
			else if(BASICBANKen)pDATA <= BBCBASIC2[pADDRESSBUS[13:0]];
		end else begin
			if(PHI_2)
				if(RnW) pDATA <= RAM[pADDRESSBUS[14:0]]; // processor
				else	RAM[pADDRESSBUS[14:0]] <= DATABUS;
			else 		vDATA <= RAM[vADDRESSBUS];			// crtc
		end
	end

/******************************************************************************/
//	Chip selects

	wire SHEILA = &pADDRESSBUS[15:9] & ~pADDRESSBUS[8];

	wire nCRTC = ~(SHEILA & ~|pADDRESSBUS[7:3]);
	wire nACIA = ~(SHEILA & ~|pADDRESSBUS[7:4] & pADDRESSBUS[3]);
	wire nVIDPROC = ~(SHEILA & ~|pADDRESSBUS[7:6] & pADDRESSBUS[5] & ~pADDRESSBUS[4] & ~RnW);
	wire nROMSEL  = ~(SHEILA & ~|pADDRESSBUS[7:6] & pADDRESSBUS[5] & pADDRESSBUS[4] & ~RnW);

	wire nVIA = ~(SHEILA & ~pADDRESSBUS[7] & pADDRESSBUS[6] & ~pADDRESSBUS[5]);
	wire nUVIA= ~(SHEILA & ~pADDRESSBUS[7] & &pADDRESSBUS[6:5]);
	wire nFDC = ~(SHEILA & pADDRESSBUS[7] & ~|pADDRESSBUS[6:5]);
	wire nADC = ~(SHEILA & &pADDRESSBUS[7:6] & ~pADDRESSBUS[5]);
	wire nTUBE= ~(SHEILA & &pADDRESSBUS[7:5]);

/******************************************************************************/
// CRTC address correction

	wire LS259en = nVIA;
	reg [7:0] LS259_reg;
	wire LS259_D;
	wire [2:0] LS259_A;

	always @ ( posedge CLK_PROC ) begin
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
	end

	wire B1 = ~&{LS259_reg[4],LS259_reg[5],cFRAMESTORE[12]};
	wire B2 = ~&{B3,LS259_reg[5],cFRAMESTORE[12]};
	wire B3 = ~&{LS259_reg[4],cFRAMESTORE[12]};
	wire B4 = ~&{B3,cFRAMESTORE[12]};

	wire [3:0] caa = cFRAMESTORE[11:8] + {B4,B3,B2,B1} + 1'b1; // CRTC adjusted address
	assign vADDRESSBUS = {caa,cFRAMESTORE[7:0],cROWADDRESS[2:0]};

/******************************************************************************/

// Processor
	MOS6502 pocessor(
	.clk(CLK_PROC),
	.nRES(nMASTER_RESET),
	.nIRQ(nIRQ),
	.nNMI(VCC),.SO(VCC),.READY(VCC),
	.Data_bus(DATABUS),

	.Address_bus(pADDRESSBUS),
	.PHI_2(PHI_2),
	.RnW(RnW));


// Video ULA
	assign DISEN = cDISPLAYen&~cROWADDRESS[3];
	VideoULA vula(
	.PIXELCLK(PIXELCLK),
	.nRESET(nMASTER_RESET),
	.A0(pADDRESSBUS[0]),
	.nCS(nVIDPROC),
	.DISEN(DISEN),
	.CURSOR(CURSOR),
	.DATA(vDATA),
	.pDATA(DATABUS),

	.CLK_RAM(CLK_RAM),
	.CLK_PROC(CLK_PROC),
	.CLK_hPROC(CLK_hPROC),
	.CLK_CRTC(CLK_CRTC),
	.REDout(RED),
	.GREENout(GREEN),
	.BLUEout(BLUE));

// CRTC
	VGA_CRTC crtc(
	.En(PHI_2),
	.PIXELCLK(PIXELCLK),
	.CHARCLK(CLK_CRTC),
	.nCS(nCRTC),
	.nRESET(nMASTER_RESET),
	.RnW(RnW),
	.RS(pADDRESSBUS[0]),
	.DATABUS(DATABUS),

	.framestore_adr(cFRAMESTORE),
	.scanline_row(cROWADDRESS),
	.DISEN(cDISPLAYen),
	.CURSOR(CURSOR),
	.H_SYNC(VGA_HS),
	.V_SYNC(VGA_VS));


// Versatile Interface Adapter
	MOS6522 via(
	.CS1(VCC),
	.nCS2(nVIA),
	.nRESET(nMASTER_RESET),
	.PHI_2(PHI_2),
	.RnW(RnW),
	.RS(pADDRESSBUS[3:0]),
	.CA1(VGA_VSYNC),
	.CA2(COL_MATCH),

	.DATA(DATABUS),
	.PORTB({VCC_4,LS259_D,LS259_A}),
	.PORTA(PORTA),
	.nIRQ(nIRQ));

// KEYBOARD
	Keyboard k(
	.CLK_hPROC(CLK_hPROC),
	.nRESET(nMASTER_RESET),
	.autoscan(LS259_reg[3]),
	.column(PORTA[3:0]),
	.row(PORTA[6:4]),

	.PS2_CLK(PS2_CLK),
	.PS2_DATA(PS2_DATA),
	.column_match(COL_MATCH),
	.row_match(PORTA[7]));

// Extra (MOCK) Peripherals
	EXTRA_PERIPHERALS ext_p(
	.CLK_PROC(CLK_PROC),
	.RnW(RnW),
	.nRESET(nMASTER_RESET),
	.nVIA(nVIA),
	.nFDC(nFDC),
	.nADC(nADC),
	.nTUBE(nTUBE),
	.nUVIA(nUVIA),
	.nACIA(nACIA),

	.DATABUS(DATABUS));

endmodule
