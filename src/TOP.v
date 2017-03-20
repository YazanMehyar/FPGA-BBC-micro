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

	output AUD_SD,
	output AUD_PWM,

	input  SD_CD,			// Active low SD card detect
	inout  [3:0] SD_DAT,
	output SD_RESET,
	output SD_SCK,
	output SD_CMD);

	wire VCC   = 1'b1;
    wire [3:0] VCC_4 = 4'hF;

/*****************************************************************************/

	wire PIXELCLK;
	wire dRAM_en;	// d as in double ram
	wire RAM_en;
	wire PROC_en;
	wire hPROC_en;	// h as in half processor
	wire CRTCF_en;
	wire CRTCS_en;
	wire PHI_2;		// PHASE 2 of MOS6502
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
		.V_TURN(V_TURN),
		.PHI_2(PHI_2));


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
	wire SYNC;
	wire usr_nIRQ;
	wire sys_nIRQ;

	wire RnW;
	wire nIRQ;
	wire COLUMN_MATCH;
	wire MOSI, MISO, SCK;
	wire SOUND;
	wire BLUE, RED, GREEN;

	wire SHEILA		= &pADDRESSBUS[15:9] & ~pADDRESSBUS[8];
	wire OSBANKen	= &pADDRESSBUS[15:14] & ~SHEILA;
	wire AUXBANKen	= pADDRESSBUS[15] & ~pADDRESSBUS[14];

	reg [3:0] ROM_BANK;
	reg [7:0] ram_DATA;
	reg [7:0] rom_DATA;
	reg [7:0] vDATA;

	assign pDATABUS =  RnW&~SHEILA?		pDATA : 8'hzz;
	assign pDATA	=  pADDRESSBUS[15]? rom_DATA : ram_DATA;
	assign nIRQ		= &{sys_nIRQ,usr_nIRQ};

//	Chip selects

	wire nCRTC = ~(SHEILA & ~|pADDRESSBUS[7:3]);
	wire nACIA = ~(SHEILA & ~|pADDRESSBUS[7:4] & pADDRESSBUS[3]);
	wire nVIDPROC = ~(SHEILA & ~|pADDRESSBUS[7:6] & pADDRESSBUS[5] & ~pADDRESSBUS[4] & ~RnW);
	wire nROMSEL  = ~(SHEILA & ~|pADDRESSBUS[7:6] & pADDRESSBUS[5] & pADDRESSBUS[4] & ~RnW);

	wire nVIA = ~(SHEILA & ~pADDRESSBUS[7] & pADDRESSBUS[6] & ~pADDRESSBUS[5]);
	wire nUVIA= ~(SHEILA & ~pADDRESSBUS[7] & &pADDRESSBUS[6:5]);
	wire nFDC = ~(SHEILA & pADDRESSBUS[7] & ~|pADDRESSBUS[6:5]);
	wire nADLC= ~(SHEILA & pADDRESSBUS[7] & ~pADDRESSBUS[6] & pADDRESSBUS[5]);
	wire nADC = ~(SHEILA & &pADDRESSBUS[7:6] & ~pADDRESSBUS[5]);
	wire nTUBE= ~(SHEILA & &pADDRESSBUS[7:5]);
	wire SLOW_PROC = ~&{nVIA,nUVIA,nADC,nACIA};

/*****************************************************************************/
//	RAM & ROMS

	always @ ( posedge PIXELCLK )
		if(PROC_en&~nROMSEL) ROM_BANK <= pDATABUS[3:0];


	always @ ( posedge PIXELCLK )
		if(RAM_en)
			if(V_TURN) begin // Respond to CRTC reads and MOS6502 writes
				vDATA <= RAM[vADDRESSBUS];
				if(~RnW&PHI_2&~pADDRESSBUS[15])
					RAM[pADDRESSBUS[14:0]] <= pDATABUS;
			end else begin
				ram_DATA <= RAM[pADDRESSBUS[14:0]];
			end

	always @ ( posedge PIXELCLK )
		if(RAM_en&~PHI_2)
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
	assign vADDRESSBUS = {caa,FRAMESTORE_ADR[7:0],ROW_ADDRESS[2:0]};

/******************************************************************************/

// Processor
	MOS6502 pocessor(
		.clk(PIXELCLK),
		.clk_en(SLOW_PROC? hPROC_en : PROC_en),
		.PHI_2(PHI_2),
		.nRESET(CPU_RESETN),
		.SYNC(SYNC),
		.nIRQ(nIRQ),
		.nNMI(VCC),
		.nSO(VCC),
		.READY(VCC),
		.Data_bus(pDATABUS),
		.Address_bus(pADDRESSBUS),
		.RnW(RnW)
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
		.PHI_2(PHI_2),
		.nCS_CRTC(nCRTC),
		.nCS_VULA(nVIDPROC),
		.RnW(RnW),
		.A0(pADDRESSBUS[0]),
		.vDATABUS(vDATA),
		.pDATABUS(pDATABUS),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.RED(RED),
		.GREEN(GREEN),
		.BLUE(BLUE),
		.FRAMESTORE_ADR(FRAMESTORE_ADR),
		.ROW_ADDRESS(ROW_ADDRESS)
	);

// System VIA
	MOS6522 sys_via(
		.clk(PIXELCLK),
		.clk_en(hPROC_en),
		.nRESET(CPU_RESETN),
		.CS1(VCC),
		.nCS2(nVIA),
		.PHI_2(PHI_2),
		.RnW(RnW),
		.RS(pADDRESSBUS[3:0]),
		.CA1(VGA_VS),
		.CA2(COLUMN_MATCH),
		.CB1(VCC),
		.CB2(VCC),
		.DATA(pDATABUS),
		.PORTA(PORTA),
		.PORTB({VCC_4,LS259_D,LS259_A}),
		.nIRQ(sys_nIRQ)
	);

// User VIA
	MOS6522 usr_via(
		.clk(PIXELCLK),
		.clk_en(hPROC_en),
		.nRESET(CPU_RESETN),
		.CS1(VCC),
		.nCS2(nUVIA),
		.PHI_2(PHI_2),
		.RnW(RnW),
		.RS(pADDRESSBUS[3:0]),
		.CA1(VCC),
		.CA2(VCC),
		.CB1(SCK),
		.CB2(MISO),
		.DATA(pDATABUS),
		.PORTB({VCC_4,VCC,VCC,SCK,MOSI}),
		.nIRQ(usr_nIRQ)
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
		.row_match(PORTA[7])
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
		.PHI_2(PHI_2),
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
	assign VGA_R = {4{RED}};
	assign VGA_G = {4{GREEN}};
	assign VGA_B = {4{BLUE}};
	assign LED[0] = ~SD_CD;
	assign SD_RESET = 0;
	assign SD_SCK = SCK;
	assign SD_CMD = MOSI;
	assign MISO = SD_DAT[0];
	assign SD_DAT[3:1] = 3'b000;

// TEST_ASSISTANCE
`ifdef SIMULATION

`endif

endmodule
