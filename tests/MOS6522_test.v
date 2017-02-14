module MOS6522_test ();

`define CLK_PEROID 10

initial begin
	$dumpvars(0, MOS6522_test);
end

// Input
reg CS1, nCS2;
reg nRESET;
reg PHI_2;
reg RnW;
reg [3:0] RS;
reg CA1, CA2;

wire [7:0] DATA;
wire [7:0] PORTA;
wire [7:0] PORTB;

wire nIRQ;

MOS6522 via(
	.CS1(CS1),
	.nCS2(nCS2),
	.RnW(RnW),
	.PHI_2(PHI_2),
	.nRESET(nRESET),
	.RS(RS),
	.CA1(CA1),
	.CA2(CA2),

	.DATA(DATA),
	.PORTA(PORTA),
	.PORTB(PORTB),

	.nIRQ(nIRQ));

/****************************************************************************************/

initial PHI_2 = 0;
always #(`CLK_PEROID/2) PHI_2 = ~PHI_2;

assign DATA = (~RnW&PHI_2)? DATA_REG : 8'hzz;

reg [7:0] DATA_REG;

initial begin
	CA1 <= 0; CA2 <= 0;
	nRESET <= 0; CS1 <= 0; nCS2 <= 1; RnW <= 1;
	repeat (10) @(posedge PHI_2);

	nRESET <= 1;
	repeat (10) @(posedge PHI_2);

	CS1 <= 1; nCS2 <= 0; RS <= 2; RnW <= 0;
	DATA_REG <= 8'h0F;
	@(posedge PHI_2);
	CS1 <= 0; DATA_REG <= 8'hAA;
	repeat (10) @(posedge PHI_2);
	CS1 <= 1; RS <= 0; DATA_REG <= 8'h0D;
	@(posedge PHI_2);
	CS1 <= 0; DATA_REG <= 8'hAA;
	repeat (10) @(posedge PHI_2);

	CS1 <= 1; RS <= 14; DATA_REG <= 8'h7F;
	@(posedge PHI_2);
	RS <= 13;
	@(posedge PHI_2);
	CS1 <= 0; DATA_REG <= 8'hAA;
	repeat (10) @(posedge PHI_2);

	CS1 <= 1; RS <= 14; DATA_REG <= 8'hF2;
	@(posedge PHI_2);
	RS <= 12; DATA_REG <= 8'h04;
	@(posedge PHI_2);
	RS <= 11; DATA_REG <= 8'h60;
	@(posedge PHI_2);
	RS <= 6;  DATA_REG <= 8'h0E;
	@(posedge PHI_2);
	RS <= 7;  DATA_REG <= 8'h01;
	@(posedge PHI_2);
	RS <= 5;
	@(posedge PHI_2);
	CS1 <= 0;
	repeat (400) @(posedge PHI_2);

	CS1 <= 1; RS <= 4; RnW <= 1;
	@(posedge PHI_2);
	CS1 <= 0;
	repeat (200) @(posedge PHI_2);

	CS1 <= 1; RS <= 4; RnW <= 1;
	@(posedge PHI_2);
	CS1 <= 0;
	repeat (100) @(posedge PHI_2);

	CA1 <= 1;
	@(posedge PHI_2);
	CA1 <= 0;
	repeat (100) @(posedge PHI_2);

	CS1 <= 1; RS <= 1;
	@(posedge PHI_2);
	CS1 <= 0;
	repeat (100) @(posedge PHI_2);
	$finish;
end

endmodule // MOS6522_test
