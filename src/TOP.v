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
	`define KiB64 65535

	wire VCC = 1'b1;
	wire GND = 1'b0;

	wire [15:0] pADDRESSBUS;
	wire [13:0] cFRAMESTORE;
	wire [4:0] cROWADDRESS;

	wire clk2MHz, clk4MHz, clk1MHz, clkCRTC;
	wire cDISPLAYen, CURSOR, DISEN;
	wire VGA_HSYNC, VGA_VSYNC;
	wire PHI_2, RnW, nIRQ;
	wire RED, GREEN, BLUE;

/*****************************************************************************/

	assign VGA_HS = VGA_HSYNC;
	assign VGA_VS = VGA_VSYNC;

	assign VGA_R = {4{RED}};
	assign VGA_G = {4{GREEN}};
	assign VGA_B = {4{BLUE}};

/*****************************************************************************/
	reg clk16MHz;
	reg [3:0] CLKPHASE = 0;
	always @(posedge CLK100MHZ) begin
		if(~CPU_RESETN) begin
			CLKPHASE <= 4'h1;
			clk16MHz <= 0;
		end else begin
			CLKPHASE <= {CLKPHASE[3:0],CLKPHASE[3]};
			if(CLKPHASE[3]) clk16MHz <= ~clk16MHz;
		end
	end

	VGA vga(
		.nRESET(CPU_RESETN),
		.CLK100MHZ(CLK100MHZ),
		.VGA_HSYNC(VGA_HSYNC),
		.VGA_VSYNC(VGA_VSYNC)
		);

/****************************************************************************/

	`include "BBCOS12.vh"
	`include "BBCBASIC2.vh"

	// ROM Bank Select
	reg [3:0] ROM_BANK;
	always @ ( posedge clk2MHz ) begin
		if(~nROMSEL) ROM_BANK <= DATABUS[3:0];
	end

	// ROM
	wire OSBANKen 	 = &pADDRESSBUS[15:14] & ~SHEILA;
	wire BASICBANKen = pADDRESSBUS[15] & ~pADDRESSBUS[14] & ~|ROM_BANK;

	reg [7:0] RAM [0:`KiB32];
	reg [7:0] MEM_DATA;
	wire [7:0] DATABUS = RnW&~SHEILA? MEM_DATA:8'hzz;
	wire [14:0] CRTC_adr;

	always @ ( negedge clk4MHz ) begin
		if(PHI_2 & pADDRESSBUS[15]) begin
			if(OSBANKen) 		MEM_DATA <= BBCOS12[pADDRESSBUS[13:0]];
			else if(BASICBANKen)MEM_DATA <= BBCBASIC2[pADDRESSBUS[13:0]];
			else MEM_DATA <= 8'hFF;
		end else begin
			if(PHI_2)
				if(RnW) MEM_DATA <= RAM[pADDRESSBUS[14:0]]; // processor
				else	RAM[pADDRESSBUS[14:0]] <= DATABUS;
			else 		MEM_DATA <= RAM[CRTC_adr];			// crtc
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

	wire LS259en = nVIA;
	reg [7:0] LS259_reg;
	wire LS259_D;
	wire [2:0] LS259_A;

	always @ ( posedge clk2MHz ) begin
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
	assign CRTC_adr = {caa,cFRAMESTORE[7:0],cROWADDRESS[2:0]};

/******************************************************************************/

// Processor
	MOS6502 pocessor(
	.clk(clk2MHz),
	.nRES(CPU_RESETN),
	.nIRQ(nIRQ),
	.nNMI(VCC),.SO(VCC),.READY(VCC),
	.Data_bus(DATABUS),

	.Address_bus(pADDRESSBUS),
	.PHI_2(PHI_2),
	.RnW(RnW));


// Video ULA
	assign DISEN = cDISPLAYen&~cROWADDRESS[3];
	VideoULA vula(
	.clk16MHz(clk16MHz),
	.nRESET(CPU_RESETN),
	.A0(pADDRESSBUS[0]),
	.nCS(nVIDPROC),
	.DISEN(DISEN),
	.CURSOR(CURSOR),
	.DATA(MEM_DATA),
	.pDATA(DATABUS),

	.clk4MHz(clk4MHz),
	.clk2MHz(clk2MHz),
	.clk1MHz(clk1MHz),
	.clkCRTC(clkCRTC),
	.REDout(RED),
	.GREENout(GREEN),
	.BLUEout(BLUE));


// CRTC, NB HSYNC and VSYNC produced by VGA module
	MC6845 crtc(
	.en(PHI_2),
	.char_clk(clkCRTC),
	.nCS(nCRTC),
	.nRESET(CPU_RESETN),
	.RnW(RnW),
	.RS(pADDRESSBUS[0]),
	.data_bus(DATABUS),

	.framestore_adr(cFRAMESTORE),
	.scanline_row(cROWADDRESS),
	.display_en(cDISPLAYen),
	.cursor(CURSOR));

wire [3:0] VCC_4 = 4'hF;
wire [3:0] PORTB_lo;
wire [7:0] PORTA;
wire COL_MATCH;

// Versatile Interface Adapter
	MOS6522 via(
	.CS1(VCC),
	.nCS2(nVIA),
	.nRESET(CPU_RESETN),
	.PHI_2(PHI_2),
	.RnW(RnW),
	.RS(pADDRESSBUS[3:0]),
	.CA1(VGA_VSYNC),
	.CA2(COL_MATCH),

	.DATA(DATABUS),
	.PORTB({VCC_4,PORTB_lo}),
	.PORTA(PORTA),
	.nIRQ(nIRQ));

// KEYBOARD
	Keyboard k(
	.clk1MHz(clk1MHz),
	.clk2MHz(clk2MHz),
	.nRESET(CPU_RESETN),
	.autoscan(LS259_reg[3]),
	.column(PORTA[3:0]),
	.row(PORTA[6:4]),

	.PS2_CLK(PS2_CLK),
	.PS2_DATA(PS2_DATA),
	.column_match(COL_MATCH),
	.row_match(PORTA[7]));

// Extra (MOCK) Peripherals
	EXTRA_PERIPHERALS ext_p(
	.clk2MHz(clk2MHz),
	.RnW(RnW),
	.nRESET(CPU_RESETN),
	.nVIA(nVIA),
	.nFDC(nFDC),
	.nADC(nADC),
	.nTUBE(nTUBE),
	.nUVIA(nUVIA),
	.nACIA(nACIA),

	.DATABUS(DATABUS));

endmodule
