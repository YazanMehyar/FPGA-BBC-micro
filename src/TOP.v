`include "TOP.vh"

module TOP(
	input CLK100MHZ,
	input PS2_CLK,
	input PS2_DATA,
	input CPU_RESETN,

	output [3:0] VGA_R,
	output [3:0] VGA_G,
	output [3:0] VGA_B,
	output VGA_HS,
	output VGA_VS,
	
	input [15:0] SW,
	output[15:0] LED,
	
	output AUD_SD,
	output AUD_PWM,
	
	input  SD_CD,			// Active low SD card detect
	output [3:0] SD_DAT,
	output SD_RESET,
	output SD_SCK,
	output SD_CMD
	);

	wire VCC   = 1'b1;
    wire [3:0] VCC_4 = 4'hF;
    wire GND   = 1'b0;

/*****************************************************************************/

	wire [13:0] FRAMESTORE_ADR;
	wire [4:0] ROW_ADDRESS;

	wire RnW, nIRQ;
	wire [7:0] PORTA;
	wire COLUMN_MATCH;
	wire RED, GREEN, BLUE;
	wire SOUND;

/*****************************************************************************/

	assign AUD_SD  = 1'b1;				 // audio enable
	assign AUD_PWM = SOUND? 1'bz : 1'b0; // Pull up resistor by FPGA
	assign VGA_R = {4{RED}};
	assign VGA_G = {4{GREEN}};
	assign VGA_B = {4{BLUE}};
	assign SD_DAT[3]= 1'b0;	// Active low chip select (in SPI mode)
	assign SD_DAT[0]= 1'b1;
	assign SD_RESET = 1'b0; // Active High Reset
	
	assign LED[0] = ~SD_CD;
	assign LED[15]= SD_DAT[3];

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

	reg [7:0] RAM [0:`KiB32];
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

	wire [7:0] pDATABUS;
	wire [7:0] pDATA; // processor

	wire OSBANKen 	 = &pADDRESSBUS[15:14] & ~SHEILA;
	wire BASICBANKen = pADDRESSBUS[15] & ~pADDRESSBUS[14] & ~|ROM_BANK;
	wire DFSen  	 = pADDRESSBUS[15] & ~pADDRESSBUS[14] & (ROM_BANK == 4'h1);


	reg [3:0] ROM_BANK;
	reg [7:0] ram_DATA;
	reg [7:0] rom_DATA;
	reg [7:0] vDATA;

	assign pDATABUS =  RnW&~SHEILA?		pDATA : 8'hzz;
	assign pDATA	=  pADDRESSBUS[15]? rom_DATA : ram_DATA;

	always @ ( posedge PIXELCLK )
		if(PROC_en&~nROMSEL) ROM_BANK <= pDATABUS[3:0];


	always @ ( posedge PIXELCLK )
		if(RAM_en) begin
			if(V_TURN) begin // Respond to CRTC reads and MOS6502 writes
				vDATA <= RAM[vADDRESSBUS];
				if(~RnW&PHI_2&~pADDRESSBUS[15])
					RAM[pADDRESSBUS[14:0]] <= pDATABUS;
			end else
				ram_DATA <= RAM[pADDRESSBUS[14:0]];
		end

	always @ ( posedge PIXELCLK )
		if(RAM_en&~PHI_2)
			if(OSBANKen) 			rom_DATA <= BBCOS12[pADDRESSBUS[13:0]];
			else if(BASICBANKen)	rom_DATA <= BBCBASIC2[pADDRESSBUS[13:0]];
			else if(DFSen)			rom_DATA <= DFS[pADDRESSBUS[13:0]];

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
	wire nADLC= ~(SHEILA & pADDRESSBUS[7] & ~pADDRESSBUS[6] & pADDRESSBUS[5]);
	wire nADC = ~(SHEILA & &pADDRESSBUS[7:6] & ~pADDRESSBUS[5]);
	wire nTUBE= ~(SHEILA & &pADDRESSBUS[7:5]);

/******************************************************************************/
// CRTC address correction

	wire LS259en = nVIA&PROC_en;
	reg [7:0] LS259_reg;
	wire LS259_D;
	wire [2:0] LS259_A;

	always @ ( posedge PIXELCLK ) begin
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

	wire B1 = ~&{LS259_reg[4],LS259_reg[5],FRAMESTORE_ADR[12]};
	wire B2 = ~&{B3,LS259_reg[5],FRAMESTORE_ADR[12]};
	wire B3 = ~&{LS259_reg[4],FRAMESTORE_ADR[12]};
	wire B4 = ~&{B3,FRAMESTORE_ADR[12]};

	wire [3:0] caa = FRAMESTORE_ADR[11:8] + {B4,B3,B2,B1} + 1'b1;
	assign vADDRESSBUS = {caa,FRAMESTORE_ADR[7:0],ROW_ADDRESS[2:0]};

/******************************************************************************/
	wire SLOW_PROC = ~&{nVIA,nUVIA,nADC,nACIA};

wire SYNC;
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
	.RnW(RnW));

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
	.ROW_ADDRESS(ROW_ADDRESS));
	
wire usr_nIRQ;
wire sys_nIRQ;
assign nIRQ = sys_nIRQ&(usr_nIRQ|SD_CD);

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
	.nIRQ(sys_nIRQ));

wire [7:0] HiZ_8 = 8'hzz;
wire HiZ_1 = 1'bz;
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
	.CA2(HiZ_1),
	.CB1(SD_SCK),
	.CB2(SD_DAT[0]),
	.DATA(pDATABUS),
	.PORTA(HiZ_8),
	.PORTB({VCC_4,VCC,VCC,SD_SCK,SD_CMD}),
	.nIRQ(usr_nIRQ));

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
	.row_match(PORTA[7]));
	
// Sound
	Sound_Generator sound(
	.clk(PIXELCLK),
	.clk_en(PROC_en),
	.nWE(LS259_reg[0]),
	.DATA(PORTA),
	.PWM(SOUND));


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
	.DATABUS(pDATABUS));

/**************************************************************************************************/
// TEST_ASSISTANCE
`ifdef SIMULATION
	reg CATCH = 0;
	always @ (posedge PHI_2) begin
		if(~nUVIA) begin
			$display("User via access @ %012t", $time);
			$display("\tRegister: %d", pADDRESSBUS[3:0]);
			#1 $display("\tValue is: %02H - %s", pDATABUS, RnW? "READ":"WRITE");
		end
	end
`endif

endmodule
