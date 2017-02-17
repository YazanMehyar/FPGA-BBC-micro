module TOP_test();

	`define KiB16 65535
	`define KiB32 131071

	initial $dumpvars(0, TOP_test);

	reg clk16MHz = 0;
	always #(`CLK16MHzPERIOD/2) clk16MHz = ~clk16MHz;

	wire VCC = 1'b1;
	wire GND = 1'b0;

	wire [15:0] pADDRESSBUS;
	wire [13:0] cFRAMESTORE;
	wire [4:0] cROWADDRESS;
	wire [7:0] DATABUS = SHEILA? ;

	wire clk2MHz, clk4MHz, clkCRTC;
	wire cDISPLAYen, DISPLAYen;
	wire H_SYNC, V_SYNC;
	wire PHI_2, RnW, SYNC, nIRQ;
	wire RED, GREEN, BLUE;

	// ROM
	wire OSBANKen = (&pADDRESSBUS[15:14] & ~SHEILA);
	wire BASICBANKen = (pADDRESSBUS[15] & ~pADDRESSBUS[14]);

	reg [7:0] OSROM [0:`KiB16];
	reg [7:0] BASICROM [0:`KiB16];
	reg [7:0] RAM [0:`KiB32];
	reg [7:0] MEM_DATA;
		
	always @ ( posedge clk4MHz ) begin
		if(clk2MHz & pADDRESSBUS[15]) begin
			if(OSBANKen) MEM_DATA <= OSROM[pADDRESSBUS[13:0]];
			else if(BASICBANKen) MEM_DATA <= BASICROM[pADDRESSBUS[13:0]];
			else MEM_DATA <= 8'hxx;
		end else begin
			if(clk2MHz) // respond to processor
				MEM_DATA <= RAM[pADDRESSBUS[14:0];
			else		// respond to CRTC
				MEM_DATA <= RAM[{cFRAMESTORE[7:4],adr_sum[2:0],cFRAMESTORE[3:0],cROWADDRESS[2:0]}];
		end
	end

/******************************************************************************/

	// address correction
	wire B1 = ~&{LS259_reg[4],LS259_reg[5],cFRAMESTORE[12]};
	wire B2 = ~&{B3,LS259_reg[5],cFRAMESTORE[12]};
	wire B3 = ~&{LS259_reg[4],cFRAMESTORE[12]}; 
	wire B4 = ~&{B3,cFRAMESTORE[12]};
	reg [3:0] adr_sum;
	
	always ( * ) begin
		adr_sum = cFRAMESTORE[11:8] + {B4,B3,B2,B1} + 1'b1;
	end


/******************************************************************************/

	wire LS259_D;
	wire [2:0] LS259_A;
	wire LS259en = nVIA;
	reg [7:0] LS259_reg;

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

/******************************************************************************/

	wire SHEILA = &pADDRESSBUS[15:9] & ~pADDRESSBUS[8];

	wire nVIA = ~(SHEILA & ~pADDRESSBUS[7] & pADDRESSBUS[6] & ~pADDRESSBUS[5]);
	wire nVIDPROC = ~(SHEILA & ~&pADDRESSBUS[7:6] & pADDRESSBUS[5] & ~pADDRESSBUS[4] & ~RnW);
	wire nCRTC = ~(SHEILA & ~&pADDRESSBUS[7:3]);

/******************************************************************************/
	reg nRESEt;
	initial begin
		$stop;
		$start_screen;
		$readmemh("./software/OS12.ROM", OSROM);
		$readmemh("./software/BASIC2.ROM", BASICROM);
		nRESET <= 0;
		repeat (10) @(posedge clk2MHz);
		
		nRESET <= 1;
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
	always @ (posedge clk16MHz) begin
		if(V_SYNC) $v_sync;
		else if(H_SYNC) $h_sync;
		else if(cDISPLAYen) $pixel_scan(colour);
	end

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
	VideoULA vula(
	.clk16MHz(clk16MHz),
	.nRESET(nRESET),
	.A0(pADDRESSBUS[0]),
	.nCS(nVIDPROC),
	.DISEN(DISPLAYen),
	.DATA(DATABUS),

	.clk4MHz(clk4MHz),
	.clk2MHz(clk2MHz),
	.clkCRTC(clkCRTC),
	.REDout(RED),
	.GREENout(GREEN),
	.BLUEout(BLUE));


// CRTC
	MC6845 crtc(
	.en(PHI_2),
	.char_clk(clkCRTC),
	.nCS(nCRTC),
	.nRESET(nRESET),
	.RnW(RnW),
	.RS(pADDRESSBUS[0]),
	.data_bus(DATABUS),

	.framestore_adr(cFRAMESTORE),
	.cROWADDRESS(cROWADDRESS),
	.display_en(cDISPLAYen),
	.h_sync(H_SYNC),
	.v_sync(V_SYNC));

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
	.PORTB({{4{VCC}},LS259_D,LS259_A}),
	.PORTA({8{VCC}}),

	.nIRQ(nIRQ));
