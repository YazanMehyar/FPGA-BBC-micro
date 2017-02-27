`timescale 1ns/1ns

module TOP_test();

	`define KiB16 16383
	`define KiB32 32767
	`define KiB64 65535
	`define CLKPERIOD 10

	initial $dumpvars(0, TOP_test);

	reg clk100MHz = 0;
	always #(`CLKPERIOD/2) clk100MHz = ~clk100MHz;

	wire VCC = 1'b1;
	wire GND = 1'b0;
	wire [3:0] VCC_4 = 4'hF;

	wire [15:0] pADDRESSBUS;
	wire [13:0] cFRAMESTORE;
	wire [4:0] cROWADDRESS;
	wire [7:0] DATABUS = RnW&~SHEILA? MEM_DATA:8'hzz;

	wire clk2MHz, clk4MHz, clkCRTC;
	wire cDISPLAYen, CURSOR, DISEN;
	wire H_SYNC, V_SYNC;
	wire PHI_2, RnW, SYNC, nIRQ;
	wire RED, GREEN, BLUE;
	
/*****************************************************************************/

	wire PIXELCLK = PIXELCOUNT[1];
	reg [1:0] PIXELCOUNT = 0;
	always @ (posedge clk100MHz) PIXELCOUNT <= PIXELCOUNT + 1;
	
/*****************************************************************************/
	// ROM Bank Select
	reg [3:0] ROM_BANK;
	always @ ( posedge clk2MHz ) begin
		if(~nROMSEL) ROM_BANK <= DATABUS[3:0];
	end

	// ROM
	wire OSBANKen 	 = &pADDRESSBUS[15:14] & ~SHEILA;
	wire BASICBANKen = pADDRESSBUS[15] & ~pADDRESSBUS[14] & ~|ROM_BANK;

	reg [7:0] OSROM [0:`KiB16];
	reg [7:0] BASICROM [0:`KiB16];
	reg [7:0] RAM [0:`KiB32];
	reg [7:0] MEM_DATA;
	wire [14:0] CRTC_adr;

	always @ ( negedge clk4MHz ) begin
		if(PHI_2 & pADDRESSBUS[15]) begin
			if(OSBANKen) MEM_DATA <= OSROM[pADDRESSBUS[13:0]];
			else if(BASICBANKen) MEM_DATA <= BASICROM[pADDRESSBUS[13:0]];
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

	reg nRESET;
	integer SCREEN_COUNT = 0;
	initial begin
		$start_screen;
		$readmemh("./software/OS12.mem", OSROM);
		$readmemh("./software/BASIC2.mem", BASICROM);

		// -- OS MODIFICATION -- //
		$readmemh("./software/RAMinit.mem", RAM);
		OSROM[14'h0B3B] <= 8'h06; // Start at MODE 0 PREFERRED
		OSROM[14'h19E8] <= 8'h80; // Mark as 32KiB model

		OSROM[14'h19E9] <= 8'hD0; // Branch over code
		OSROM[14'h19EA] <= 8'h12;

		// OSROM[14'h1C05] <= 8'h10; // Loop at end of OS
		// OSROM[14'h1C06] <= 8'hFE;
		// -- OS MODIFICATION -- //

		nRESET <= 0;
		repeat (10) @(posedge clk100MHz);

		nRESET <= 1;
		repeat (20) begin
			@(posedge V_SYNC) $display("SCREEN No. %d", SCREEN_COUNT);
			SCREEN_COUNT <= SCREEN_COUNT + 1;
		end
		$stop;
		$finish;
	end

	reg [7:0] colour;
	always @ ( * ) begin
		case({RED,GREEN,BLUE})
			0: colour = 0;
			1: colour = 8'h03;
			2: colour = 8'h1C;
			3: colour = 8'h1F;
			4: colour = 8'hE0;
			5: colour = 8'hE3;
			6: colour = 8'hFC;
			7: colour = 8'hFF;
			default: colour = 8'hxx;
		endcase
	end

// TESTs

	always @ (posedge PHI_2) begin
		if(pADDRESSBUS == 16'hDC05) begin
		end
	end
	
// Virtual Screen
	initial forever @(negedge V_SYNC) @(posedge DISEN) $v_sync;

	initial forever @(negedge H_SYNC) @(posedge DISEN) $h_sync;

	always @(negedge PIXELCLK) if(DISEN) $pixel_scan(colour); else $pixel_scan(0);


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
	.nRES(nRESET),
	.nIRQ(nIRQ),
	.nNMI(VCC),.SO(VCC),.READY(VCC),
	.Data_bus(DATABUS),

	.Address_bus(pADDRESSBUS),
	.PHI_2(PHI_2),
	.RnW(RnW),
	.SYNC(SYNC));


// Video ULA
	assign DISEN = cDISPLAYen&~cROWADDRESS[3];
	VideoULA vula(
	.clk16MHz(PIXELCLK),
	.nRESET(nRESET),
	.A0(pADDRESSBUS[0]),
	.nCS(nVIDPROC),
	.DISEN(DISEN),
	.CURSOR(CURSOR),
	.DATA(MEM_DATA),
	.pDATA(DATABUS),

	.clk4MHz(clk4MHz),
	.clk2MHz(clk2MHz),
	.clkCRTC(clkCRTC),
	.REDout(RED),
	.GREENout(GREEN),
	.BLUEout(BLUE));


// CRTC
	VGA_CRTC crtc(
	.En(PHI_2),
	.PIXELCLK(PIXELCLK),
	.CHARCLK(clkCRTC),
	.nCS(nCRTC),
	.nRESET(nRESET),
	.RnW(RnW),
	.RS(pADDRESSBUS[0]),
	.DATABUS(DATABUS),

	.framestore_adr(cFRAMESTORE),
	.scanline_row(cROWADDRESS),
	.DISEN(cDISPLAYen),
	.CURSOR(CURSOR),
	.H_SYNC(H_SYNC),
	.V_SYNC(V_SYNC));
	

// Versatile Interface Adapter
	MOS6522 via(
	.CS1(VCC),
	.nCS2(nVIA),
	.nRESET(nRESET),
	.PHI_2(PHI_2),
	.RnW(RnW),
	.RS(pADDRESSBUS[3:0]),
	.CA1(V_SYNC),
	.CA2(VCC),

	.DATA(DATABUS),
	.PORTB({VCC_4,LS259_D,LS259_A}),
	.nIRQ(nIRQ));

	
// Extra (MOCK) Peripherals
	EXTRA_PERIPHERALS ext_p(
	.clk2MHz(clk2MHz),
	.RnW(RnW),
	.nRESET(nRESET),
	.nVIA(nVIA),
	.nFDC(nFDC),
	.nADC(nADC),
	.nTUBE(nTUBE),
	.nUVIA(nUVIA),
	.nACIA(nACIA),

	.DATABUS(DATABUS));

endmodule
