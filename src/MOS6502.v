`include "Decode_6502.vh"

module MOS6502 (
	input clk,
	input nRES,
	input nIRQ,
	input nNMI,
	input SO,
	input READY,

	inout [7:0] Data_bus,

	output [15:0] Address_bus,
	output PHI_1,
	output PHI_2,
	output RnW,
	output SYNC,

	// Test pins
	input [2:0] test_reg_select,
	output reg [7:0] test_value_out
	);

/**************************************************************************************************/

	wire ALU_COUT, ALU_VOUT, ALU_ZOUT, ALU_NOUT;
	wire [2:0] iDB_SEL, SB_SEL;
	wire [3:0] ADBL_SEL,ADBH_SEL;
	wire [3:0] ALU_FUNC;
	wire ALU_B_SEL,CARRY_IN;
	wire ACC_en, iX_en, iY_en;
	wire SP_en, PC_en, AOR_en, DIR_en, BUFF_en;
	wire PC_inc, decimal_mode;

	wire [7:0] PSR;
	wire [7:0] PCL;
	wire [7:0] PCH;
	wire [7:0] Acc;
	wire [7:0] iX;
	wire [7:0] iY;
	wire [7:0] SP;
	wire [7:0] ALU_out;

	wire [7:0] ADBL;
    wire [7:0] ADBH;

    wire [7:0] Address_bus_lo;
    wire [7:0] Address_bus_hi;


    reg [7:0] ALU_B;
    reg [7:0] SB;
    reg [7:0] iDB;

    reg [7:0] DIR;
    reg [7:0] AOR;

/**************************************************************************************************/

always @ ( * ) begin
	case(test_reg_select)
	3'b000: test_value_out = Acc;
	3'b001: test_value_out = iX;
	3'b010: test_value_out = iY;
	3'b011: test_value_out = SP;

	3'b100: test_value_out = PSR;
	3'b101: test_value_out = PCL;
	3'b110: test_value_out = PCH;
	default:test_value_out = 8'hxx;
	endcase
end

/**************************************************************************************************/

	always @ (posedge clk) begin
		if(DIR_en) DIR <= Data_bus;
		if(AOR_en) AOR <= ALU_out;
	end

	always @ ( * ) begin
		case (iDB_SEL)
			`iDB_PCL: iDB = PCL;
			`iDB_PCH: iDB = PCH;
			`iDB_SB : iDB = SB;
			`iDB_DIR: iDB = DIR;
			`iDB_ACC: iDB = Acc;
			`iDB_PSR: iDB = PSR;
			`iDB_ABH: iDB = ADBH;
			default: iDB = 8'hxx;
		endcase
	end

	always @ ( * ) begin
		case (SB_SEL)
			`SB_iDB: SB = iDB;
			`SB_ACC: SB = Acc;
			`SB_iX:  SB = iX;
			`SB_iY:  SB = iY;
			`SB_SP:  SB = SP;
			`SB_AOR: SB = AOR;
			default: SB = 8'hxx;
		endcase
	end

	always @ ( * ) begin
		case (ALU_B_SEL)
			`ALUB_iDB: ALU_B = iDB;
			`ALUB_ADL: ALU_B = ADBL;
			default: ALU_B = 8'hxx;
		endcase
	end

/**************************************************************************************************/

	assign Address_bus = {Address_bus_hi, Address_bus_lo};
	assign Data_bus = ~RnW & PHI_2? iDB : 8'hzz;

/**************************************************************************************************/

Control_6502 control(
	.clk(clk),
	.DIR(DIR), .iDB(iDB),
	.ALU_COUT(ALU_COUT), .ALU_VOUT(ALU_VOUT), .ALU_ZOUT(ALU_ZOUT), .ALU_NOUT(ALU_NOUT),
	.RESET_pin(nRES),.NMI_pin(nNMI),.IRQ_pin(nIRQ),.READY_pin(READY),.SO_pin(SO),.SYNC_pin(SYNC),
	.PHI_1(PHI_1),.PHI_2(PHI_2),
	.iDB_SEL(iDB_SEL),.SB_SEL(SB_SEL),.ADBL_SEL(ADBL_SEL),.ADBH_SEL(ADBH_SEL),
	.ALU_FUNC(ALU_FUNC),.ALU_B_SEL(ALU_B_SEL),.CARRY_IN(CARRY_IN),
	.RnW(RnW),
	.ACC_en(ACC_en),.iX_en(iX_en),.iY_en(iY_en),
	.SP_en(SP_en),.PC_en(PC_en),.AOR_en(AOR_en),.DIR_en(DIR_en),.BUFF_en(BUFF_en),
	.PC_inc(PC_inc),.PSR_out(PSR),.decimal_mode(decimal_mode));

ALU_6502 alu(
	.ALU_FUNC(ALU_FUNC), .D_flag(decimal_mode), .CARRY_IN(CARRY_IN), .SB(SB), .ALU_B(ALU_B),
	.ALU_COUT(ALU_COUT), .ALU_VOUT(ALU_VOUT),   .ALU_NOUT(ALU_NOUT), .ALU_ZOUT(ALU_ZOUT),
	.ALU_out(ALU_out));

Reg_Bank reg_bank(
	.clk(clk), .RESET_pin(nRES),
	.SB(SB),
	.ACC_en(ACC_en), .iX_en(iX_en),
	.iY_en(iY_en),   .SP_en(SP_en),
	.Acc(Acc), .iX(iX), .iY(iY), .SP(SP));

Address_bus addr_bus(
	.clk(clk),
	.ADBL_SEL(ADBL_SEL),
	.PCL(PCL), .AOR(AOR),
	.DIR(DIR), .SP(SP),
	.ADBH_SEL(ADBH_SEL),
	.PCH(PCH),
	.BUFF_en(BUFF_en),
	.ADB_lo(ADBL), .ADB_hi(ADBH),
	.ADB_lo_pin(Address_bus_lo),
	.ADB_hi_pin(Address_bus_hi));

Program_Counter pc(
	.clk(clk),
	.nRES(nRES),
	.ADB_lo(ADBL),
	.ADB_hi(ADBH),
	.PC_en(PC_en),
	.PC_inc(PC_inc),
	.PCL(PCL),
	.PCH(PCH));


endmodule // MOS_6502
