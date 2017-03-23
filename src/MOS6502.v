`include "MOS6502.vh"

module MOS6502 (
	// Test pins
	input [3:0] DEBUG_SEL,
	output reg [23:0] DEBUG_TAG,
	output reg [15:0] DEBUG_VAL,

	input clk,
	input clk_en,
	input nRESET,
	input nIRQ,
	input nNMI,
	input nSO,
	input READY,

	inout [7:0] Data_bus,

	output [15:0] Address_bus,
	output RnW,
	output SYNC);

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
	reg  [7:0] PCL;
	reg  [7:0] PCH;
	reg  [7:0] Acc;
	reg  [7:0] iX;
	reg  [7:0] iY;
	reg  [7:0] SP;
	wire [7:0] ALU_out;

	reg  [7:0] ADBL;
    reg  [7:0] ADBH;

    reg [7:0] ALU_B;
    reg [7:0] SB;
    reg [7:0] iDB;

    reg [7:0] DIR;
    reg [7:0] AOR;

/**************************************************************************************************/
// TEST HELPER

	always @ ( * ) begin
		casex(DEBUG_SEL)
		4'bx000: DEBUG_VAL = {8'h00,Acc};
		4'bx001: DEBUG_VAL = {8'h00,iX};
		4'bx010: DEBUG_VAL = {8'h00,iY};
		4'bx011: DEBUG_VAL = {8'h00,SP};
		4'bx100: DEBUG_VAL = {8'h00,PSR};
		4'bx101: DEBUG_VAL = {PCH,PCL};
		default:DEBUG_VAL = 8'hxx;
		endcase

		casex (DEBUG_SEL)
		4'bx000: DEBUG_TAG = {`dlA,`dlC,`dlC,`dlSP};
		4'bx001: DEBUG_TAG = {`dlI,`dlN,`dlX,`dlSP};
		4'bx010: DEBUG_TAG = {`dlI,`dlN,`dlY,`dlSP};
		4'bx011: DEBUG_TAG = {`dlS,`dlP,`dlSP,`dlSP};
		4'bx100: DEBUG_TAG = {`dlP,`dlS,`dlR,`dlSP};
		4'bx101: DEBUG_TAG = {`dlP,`dlC,`dlSP,`dlSP};
		default: DEBUG_TAG = 24'hxxx_xxx;
		endcase
    end

/**************************************************************************************************/
// Data paths

	assign Data_bus = ~RnW? iDB : 8'hzz;

	always @ (posedge clk) begin
		if(clk_en) begin
			if(DIR_en) DIR <= Data_bus;
			if(AOR_en) AOR <= ALU_out;
		end
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
// Register Bank

    always @ (posedge clk) begin
	    if(~nRESET) begin
		    SP  <= 8'h00;
		    Acc <= 8'h00;
		    iX  <= 8'h00;
		    iY  <= 8'h00;
	    end else if(clk_en) begin
		    if(SP_en)  SP  <= SB;
		    if(ACC_en) Acc <= SB;
		    if(iX_en)  iX  <= SB;
		    if(iY_en)  iY  <= SB;
	    end
    end

/**************************************************************************************************/
// Program Counter

    always @ (posedge clk) begin
	    if(~nRESET) begin
		    PCL <= 8'h00;
		    PCH <= 8'h00;
	    end else if(clk_en)
	    	if(PC_en) begin
			    PCL <= ADBL + PC_inc;
			    PCH <= ADBH + (&ADBL? PC_inc : 0);
	    	end
    end

/**************************************************************************************************/
// Memory Addressing

	reg [7:0] buff_lo, buff_hi;

	assign Address_bus = {ADBH_SEL[3]? buff_hi:ADBH, ADBL_SEL[3]? buff_lo:ADBL};

	always @ (posedge clk) begin
		if(clk_en)
			if(BUFF_en) begin
				buff_hi <= ADBH;
				buff_lo <= ADBL;
			end
	end

	// ADBL
	always @ ( * ) begin
		case (ADBL_SEL[2:0])
			`ADBL_PCL:   ADBL = PCL;
			`ADBL_AOR:   ADBL = AOR;
			`ADBL_STACK: ADBL = SP;
			`ADBL_DIR:   ADBL = DIR;
			`ADBL_IRQ:   ADBL = `IRQ_LOW_VEC;
			`ADBL_NMI:   ADBL = `NMI_LOW_VEC;
			`ADBL_RESET: ADBL = `RES_LOW_VEC;
			`ADBL_BUFFER:ADBL = buff_lo;
			default: ADBL = 8'hxx;
		endcase
	end

	// ADBH
	always @ ( * ) begin
		case (ADBH_SEL[2:0])
			`ADBH_PCH:   ADBH = PCH;
			`ADBH_AOR:   ADBH = AOR;
			`ADBH_DIR:   ADBH = DIR;
			`ADBH_ZPG:   ADBH = 8'h00;
			`ADBH_STACK: ADBH = 8'h01;
			`ADBH_VECTOR:ADBH = 8'hFF;
			`ADBH_BUFFER:ADBH = buff_hi;
			default: ADBH = 8'hxx;
		endcase
	end

/**************************************************************************************************/

MOS6502_Control control(
	.clk(clk),
	.clk_en(clk_en),
	.DIR(DIR),
	.iDB(iDB),
	.ALU_COUT(ALU_COUT),
	.ALU_VOUT(ALU_VOUT),
	.ALU_ZOUT(ALU_ZOUT),
	.ALU_NOUT(ALU_NOUT),
	.nRESET(nRESET),
	.nNMI(nNMI),
	.nIRQ(nIRQ),
	.READY_pin(READY),
	.nSO(nSO),
	.SYNC_pin(SYNC),
	.iDB_SEL(iDB_SEL),
	.SB_SEL(SB_SEL),
	.ADBL_SEL(ADBL_SEL),
	.ADBH_SEL(ADBH_SEL),
	.ALU_FUNC(ALU_FUNC),
	.ALU_B_SEL(ALU_B_SEL),
	.CARRY_IN(CARRY_IN),
	.RnW(RnW),
	.ACC_en(ACC_en),
	.iX_en(iX_en),
	.iY_en(iY_en),
	.SP_en(SP_en),
	.PC_en(PC_en),
	.AOR_en(AOR_en),
	.DIR_en(DIR_en),
	.BUFF_en(BUFF_en),
	.PC_inc(PC_inc),
	.PSR_out(PSR),
	.decimal_mode(decimal_mode));

MOS6502_ALU alu(
	.ALU_FUNC(ALU_FUNC),
	.D_flag(decimal_mode),
	.CARRY_IN(CARRY_IN),
	.SB(SB), .ALU_B(ALU_B),
	.ALU_COUT(ALU_COUT),
	.ALU_VOUT(ALU_VOUT),
	.ALU_NOUT(ALU_NOUT),
	.ALU_ZOUT(ALU_ZOUT),
	.ALU_out(ALU_out));

endmodule
