`include "TOP.vh"

module TOP_test();

	initial $dumpvars(0, TOP_test);

	reg CLK100MHZ = 0;
	always #(`CLKPERIOD/2) CLK100MHZ = ~CLK100MHZ;

	wire VCC = 1'b1;
	wire GND = 1'b0;
	wire [3:0] VCC_4 = 4'hF;

	wire cDISPLAYen, CURSOR, DISEN;
	wire H_SYNC, V_SYNC;
	wire RnW, SYNC, nIRQ;
	wire RED, GREEN, BLUE;

/*****************************************************************************/
	wire PIXELCLK;
	wire dRAM_en;	// d as in double ram
	wire RAM_en;
	wire PROC_en;
	wire hPROC_en;	// h as in half processor
	wire CRTC_en;
	wire PHI_2;		// PHASE 2 of MOS6502

	Timing_Generator timer(
		.CLK100MHZ(CLK100MHZ),
		.PIXELCLK(PIXELCLK),
		.dRAM_en(dRAM_en),
		.RAM_en(RAM_en),
		.PROC_en(PROC_en),
		.hPROC_en(hPROC_en),
		.PHI_2(PHI_2));

	// Simulate PS2_CLK
	wire PS2_CLK = PS2_COUNT[12];
	reg [12:0] PS2_COUNT = 0;
	always @ ( posedge PIXELCLK ) PS2_COUNT <= PS2_COUNT + 1;

/*****************************************************************************/
	wire [15:0] pADDRESSBUS;
	wire [14:0] vADDRESSBUS;

	wire [7:0] pDATABUS;
	wire [7:0] pDATA; // processor

	wire OSBANKen 	 = &pADDRESSBUS[15:14] & ~SHEILA;
	wire BASICBANKen = pADDRESSBUS[15] & ~pADDRESSBUS[14] & ~|ROM_BANK;

	reg [7:0] OSROM 	[0:`KiB16];
	reg [7:0] BASICROM	[0:`KiB16];
	reg [7:0] RAM 		[0:`KiB32];
	reg [3:0] ROM_BANK;
	reg [7:0] ram_DATA;
	reg [7:0] rom_DATA;
	reg [7:0] vDATA;

	assign pDATABUS =  RnW&~SHEILA?		pDATA : 8'hzz;
	assign pDATA	=  pADDRESSBUS[15]? rom_DATA : ram_DATA;

	always @ ( posedge PIXELCLK )
		if(PROC_en)
			if(~nROMSEL) ROM_BANK <= pDATABUS[3:0];


	always @ ( posedge PIXELCLK )
		if(RAM_en) begin
			if(PHI_2) begin // Respond to CRTC reads and MOS6502 writes
				vDATA <= RAM[vADDRESSBUS];
				if(~RnW) RAM[pADDRESSBUS] <= pDATABUS;
			end else
				ram_DATA <= RAM[pADDRESSBUS];
		end

	always @ ( posedge PIXELCLK )
		if(RAM_en&~PHI_2)
			if(OSBANKen) 			rom_DATA <= OSROM[pADDRESSBUS[13:0]];
			else if(BASICBANKen)	rom_DATA <= BASICROM[pADDRESSBUS[13:0]];

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
	reg PS2_DATA;

	`include "TEST_HELPERS.vh"

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
		// -- OS MODIFICATION -- //

		nRESET <= 0;
		PS2_DATA <= 1;
		repeat (16) @(posedge PIXELCLK);

		nRESET <= 1;
		repeat (3) @(posedge V_SYNC);

		$stop;

		// Send some keys
		PRESS_KEY(8'h4D);
		PRESS_KEY(8'h2D);
		PRESS_KEY(8'h43);
		PRESS_KEY(8'h31);
		PRESS_KEY(8'h2C);
		PRESS_KEY(8'h29);
		PRESS_KEY(8'h3D);
		PRESS_KEY(8'h29);
		PRESS_KEY(8'h4E);
		PRESS_KEY(8'h29);
		PRESS_KEY(8'h26);
		PRESS_KEY(8'h5A);
		PRESS_KEY(8'h4D);

		@(posedge V_SYNC);

		$stop;
		$finish;
	end

	integer SCREEN_COUNT = 0;
	always @ (posedge V_SYNC) begin
		$display("SCREEN No. %d", SCREEN_COUNT);
		SCREEN_COUNT <= SCREEN_COUNT + 1;
	end
/******************************************************************************/
// Address check

	always @ (posedge PHI_2) begin
		if(pADDRESSBUS == 16'h8000 && SYNC)
			$display("BASIC taking control @ %t", $stime);
	end


/******************************************************************************/

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

// Virtual Screen
	initial forever @(negedge V_SYNC) @(posedge cDISPLAYen) $v_sync;

	initial forever @(negedge H_SYNC) @(posedge cDISPLAYen) $h_sync;

	always @(negedge PIXELCLK) $pixel_scan(colour);


/******************************************************************************/

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

	wire [13:0] cFRAMESTORE;
	wire [4:0] cROWADDRESS;

	wire B1 = ~&{LS259_reg[4],LS259_reg[5],cFRAMESTORE[12]};
	wire B2 = ~&{B3,LS259_reg[5],cFRAMESTORE[12]};
	wire B3 = ~&{LS259_reg[4],cFRAMESTORE[12]};
	wire B4 = ~&{B3,cFRAMESTORE[12]};

	wire [3:0] caa = cFRAMESTORE[11:8] + {B4,B3,B2,B1} + 1'b1; // CRTC adjusted address
	assign vADDRESSBUS = {caa,cFRAMESTORE[7:0],cROWADDRESS[2:0]};

/******************************************************************************/

// Processor
	MOS6502 pocessor(
	.clk(PIXELCLK),
	.clk_en(PROC_en),
	.PHI_2(PHI_2),
	.nRESET(nRESET),
	.nIRQ(nIRQ),
	.nNMI(VCC),
	.nSO(VCC),
	.READY(VCC),
	.Data_bus(pDATABUS),
	.Address_bus(pADDRESSBUS),
	.RnW(RnW),
	.SYNC(SYNC));


// Video ULA
	assign DISEN = cDISPLAYen&~cROWADDRESS[3];
	VideoULA vula(
	.PIXELCLK(PIXELCLK),
	.nRESET(nRESET),
	.A0(pADDRESSBUS[0]),
	.nCS(nVIDPROC),
	.DISEN(DISEN),
	.CURSOR(CURSOR),
	.vDATA(vDATA),
	.pDATA(pDATABUS),
	.dRAM_en(dRAM_en),
	.RAM_en(RAM_en),
	.PROC_en(PROC_en),
	.hPROC_en(hPROC_en),
	.CRTC_en(CRTC_en),
	.REDout(RED),
	.GREENout(GREEN),
	.BLUEout(BLUE));


// CRTC
	VGA_CRTC crtc(
	.PIXELCLK(PIXELCLK),
	.PROC_en(PROC_en),
	.CRTC_en(CRTC_en),
	.PHI_2(PHI_2),
	.nCS(nCRTC),
	.nRESET(nRESET),
	.RnW(RnW),
	.RS(pADDRESSBUS[0]),
	.DATABUS(pDATABUS),
	.framestore_adr(cFRAMESTORE),
	.scanline_row(cROWADDRESS),
	.DISEN(cDISPLAYen),
	.CURSOR(CURSOR),
	.H_SYNC(H_SYNC),
	.V_SYNC(V_SYNC));


// Versatile Interface Adapter
	wire [7:0] PORTA;
	wire COLUMN_MATCH;

	MOS6522 via(
	.CS1(VCC),
	.nCS2(nVIA),
	.nRESET(nRESET),
	.PHI_2(PHI_2),
	.RnW(RnW),
	.RS(pADDRESSBUS[3:0]),
	.CA1(V_SYNC),
	.CA2(COLUMN_MATCH),
	.DATA(pDATABUS),
	.PORTA(PORTA),
	.PORTB({VCC_4,LS259_D,LS259_A}),
	.nIRQ(nIRQ));

// Keyboard
	Keyboard keyboard(
	.clk(PIXELCLK),
	.clk_en(hPROC_en),
	.nRESET(nRESET),
	.autoscan(LS259_reg[3]),
	.column(PORTA[3:0]),
	.row(PORTA[6:4]),
	.PS2_CLK(PS2_CLK),
	.PS2_DATA(PS2_DATA),
	.column_match(COLUMN_MATCH),
	.row_match(PORTA[7]));


// Extra (MOCK) Peripherals
	EXTRA_PERIPHERALS extra(
	.PHI_2(PHI_2),
	.RnW(RnW),
	.nRESET(nRESET),
	.nVIA(nVIA),
	.nFDC(nFDC),
	.nADC(nADC),
	.nTUBE(nTUBE),
	.nUVIA(nUVIA),
	.nACIA(nACIA),
	.DATABUS(pDATABUS));

endmodule
