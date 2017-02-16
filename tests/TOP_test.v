module TOP_test();

initial $dumpvars(0, TOP_test);

reg clk16MHz = 0;
always #(`CLK16MHzPERIOD/2) clk16MHz = ~clk16MHz;

wire VCC = 1'b1;
wire GND = 1'b0;

wire [15:0] pADDRESSBUS;
wire [13:0] cFRAMESTORE;
wire [4:0] cROWADDRESS;
wire [7:0] DATABUS;

wire clk2MHz, clkCRTC;
wire cDISPLAYen, DISPLAYen;
wire H_SYNC, V_SYNC;
wire PHI_2, RnW, SYNC, nIRQ;
wire RED,GREEN, BLUE;


reg nRESEt;
reg [15:0] ADDRESSBUS;
/******************************************************************************/
wire LS259_D;
wire [2:0] LS259_A;


/******************************************************************************/
initial begin
end

/*	TODO
	- LS259
	- nVIDPROC
	- nCRTC
	- nVIA
	- Address arbitrator
	- memory
*/

/******************************************************************************/

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

	VideoULA vula(
	.clk16MHz(clk16MHz),
	.nRESET(nRESET),
	.A0(ADDRESSBUS[0]),
	.nCS(nVIDPROC),
	.DISEN(DISPLAYen),
	.DATA(DATABUS),

	.clk2MHz(clk2MHz),
	.clkCRTC(clkCRTC),
	.REDout(REd),
	.GREENout(GREEN),
	.BLUEout(BLUE));


	MC6845 crtc(
	.en(PHI_2),
	.char_clk(clkCRTC),
	.nCS(nCRTC),
	.nRESET(nRESET),
	.RnW(RnW),
	.RS(ADDRESSBUS[0]),
	.data_bus(DATABUS),

	.framestore_adr(cFRAMESTORE),
	.cROWADDRESS(cROWADDRESS),
	.display_en(cDISPLAYen),
	.h_sync(H_SYNC),
	.v_sync(V_SYNC));

	MOS6522 via(
	.CS1(VCC),
	.nCS2(nVIA),
	.nRESET(nRESET),
	.PHI_2(PHI_2),
	.RnW(RnW),
	.RS(ADDRESSBUS[3:0]),
	.CA1(V_SYNC),
	.CA2(VCC),

	.DATA(DATABUS),
	.PORTB({{4{VCC}},LS259_D,LS259_A}),

	.nIRQ(nIRQ));
