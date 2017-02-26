/**
* @Author: Yazan Mehyar <zen>
* @Date:   26-Dec-2016
* @Email:  stcyazanerror@gmail.com
* @Filename: Decode_6502.v
* @Last modified by:   zen
* @Last modified time: 25-Feb-2017
*/

`include "Decode_6502.vh"
/*------------------------------------------------------------------------------------------------*/

module Decode_6502 (
	input [7:0] IR,
	input [5:0] T_state,
	input [7:0] PSR,
	input [7:0] DIR,
	input iDB7,
	input SD2,
	input COUT,
	input BX,
	input BCC,
	input NMI_req,
	input IRQ_req,
	input RESET_req,
	input READY,

	output reg [2:0] iDB_SEL,
	output reg [2:0] SB_SEL,
	output reg [3:0] ADBL_SEL,
	output reg [3:0] ADBH_SEL,
	output reg [3:0] ALU_FUNC,
	output reg ALU_B_SEL,
	output reg CARRY_IN,
	output reg RnW,
	output reg NEXT_T,
	output reg CLEAR_T,
	output reg ACC_en,
	output reg iX_en,
	output reg iY_en,
	output reg SP_en,
	output reg PC_en,
	output reg AOR_en,
	output reg DIR_en,
	output reg N_en,
	output reg Z_en,
	output reg C_en,
	output reg V_en,
	output FLAGS,
	output PLP,
	output RTI,
	output BIT,
	output BRK,
	output decimal_en);
/*------------------------------------------------------------------------------------------------*/

	wire T_1 = IR[0];
	wire T_2 = IR[1];
	wire T_3 = ~|IR[1:0];
	wire BLACK_SHEEP = IR[7] & IR[3] & ~IR[2] & ~T_1;

	wire ZPG, ABS, ABSx, ABSy, ZPGi, INDx, INDy, IMM;
	assign {ABSx,ABSy,ZPGi,INDy,ABS,IMM,ZPG,INDx} = 8'h01 << IR[4:2];
	wire ABSi = ABSy|ABSx;

	wire SBC, CMP, ADC, ORA, AND, EOR, LOAD, STORE;
	assign {SBC,CMP,LOAD,STORE,ADC,EOR,AND,ORA} = 8'h01 << IR[7:5];
	wire LDST = STORE|LOAD;

	wire RMW   = (~IR[7]|IR[6]) & IR[2] & T_2;
	wire CONTROL = T_3 & (INDx&~IR[7] | ABS&(ADC|EOR)); // ANY JUMP BUT NOT BRANCH
	wire STACK = T_3 & ~IR[7] & IMM;
	wire ACC   = T_2 & ~IR[7] & IMM;

	wire BRANCH = T_3 & INDy;
	wire RTS = T_3 & INDx & ADC;
	wire JSR = T_3 & INDx & AND;

	assign RTI = T_3 & INDx & EOR;
	assign BRK = T_3 & INDx & ORA;
	assign BIT = (ABS|ZPG) & T_3 & AND;
	assign PLP = STACK & AND;
	assign FLAGS = T_3 & ABSy & ~STORE;
	assign decimal_en = T_state[0] & (ADC|SBC) & T_1 & PSR[3];

	// PREDECODE
	wire ONE_BYTE = DIR[3] & ~(DIR[2]|DIR[0]);
	wire TWO_CYCLE = ~DIR[4] & (DIR[3]|~DIR[0]) & ~DIR[2] & (DIR[7]|DIR[1]|DIR[0]) // IMM NOT STACK
					| DIR[4] & ~DIR[2] & ~DIR[0]; // BRANCH AND FLAGS + (SOME TRANSFERS)
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

// iDB_SEL
always @ ( * ) begin
	iDB_SEL = `iDB_DIR; // default unless
	if(T_state[0]) begin
		if(BRANCH&BCC)       iDB_SEL = `iDB_ABH;
		else if(ACC)         iDB_SEL = `iDB_ACC;
		else if(BLACK_SHEEP) iDB_SEL = `iDB_SB;
	end else if(T_state[1]) begin
		iDB_SEL = `iDB_SB;
	end else if(T_state[2]) begin
		if(STACK&ORA)    iDB_SEL = `iDB_PSR;
		else if(STACK)   iDB_SEL = `iDB_ACC;
		else if(JSR|BRK) iDB_SEL = `iDB_PCH;
		else if(ZPG)     iDB_SEL = `iDB_SB;
	end else if(T_state[3]) begin
		if(JSR|BRK)      iDB_SEL = `iDB_PCL;
		else if(ZPGi|ABS)iDB_SEL = `iDB_SB;
	end else if(T_state[4]) begin
		if(BRK)          iDB_SEL = `iDB_PSR;
		else if(ABSi)    iDB_SEL = `iDB_ACC;
	end else if(T_state[5]) begin
		if(T_1) iDB_SEL = `iDB_ACC;
	end else if(SD2) begin // SPECIAL
		iDB_SEL = `iDB_SB;
	end
end

// SB_SEL
always @ ( * ) begin
	if(T_state[0]) begin
		if(STACK)                 SB_SEL = `SB_AOR;
		else if(BRANCH)           SB_SEL = `SB_iDB;
		else if(T_1|LOAD&IMM|BIT) SB_SEL = `SB_ACC;
		else if(T_2&LOAD)         SB_SEL = `SB_SP;
		else if(T_2|SBC)          SB_SEL = `SB_iX;
		else SB_SEL = `SB_iY;
	end else if(T_state[2]) begin
		if(ZPG&T_1)                         SB_SEL = `SB_ACC;
		else if(ABSy|ZPG&T_3|LDST&(ZPGi|ABSi)&T_2) SB_SEL = `SB_iY;
		else SB_SEL = `SB_iX;
	end else if(T_state[3]) begin
		if(INDy|T_3) SB_SEL = `SB_iY;
		else if(T_1) SB_SEL = `SB_ACC;
		else SB_SEL = `SB_iX;
	end else begin
		SB_SEL = `SB_AOR;
	end
end

// ADBL_SEL
always @ ( * ) begin
	if(T_state[0]) begin
		if(BRANCH&BX)         ADBL_SEL = {1'b1,`ADBL_BUFFER};
		else if(BRANCH&BCC)   ADBL_SEL = {(COUT^iDB7),`ADBL_AOR};
		else if(CONTROL&~RTS) ADBL_SEL = `ADBL_AOR;
		else ADBL_SEL = `ADBL_PCL;
	end else if(T_state[1]) begin
		ADBL_SEL = `ADBL_PCL;
	end else if(T_state[2]) begin
		if(STACK|BRK|JSR|RTS|RTI) ADBL_SEL = `ADBL_STACK;
		else if(ZPG|INDy)         ADBL_SEL = `ADBL_DIR;
		else ADBL_SEL = `ADBL_PCL;
	end else if(T_state[3]) begin
		ADBL_SEL = {ABSi&COUT,`ADBL_AOR};
	end else if(T_state[4]) begin
		if(JSR)       ADBL_SEL = `ADBL_PCL;
		else if(ABSi) ADBL_SEL = {1'b1,`ADBL_BUFFER};
		else ADBL_SEL = {INDy&COUT,`ADBL_AOR};
	end else if(T_state[5]) begin
		if(BRK&~RESET_req)    ADBL_SEL = `ADBL_RESET;
		else if(BRK&~NMI_req) ADBL_SEL = `ADBL_NMI;
		else if(BRK)         ADBL_SEL = `ADBL_IRQ;
		else ADBL_SEL = {INDy,`ADBL_AOR};
	end else begin
		if(BRK) ADBL_SEL = `ADBL_PCL;
		else    ADBL_SEL = {1'b1,`ADBL_BUFFER};
	end
end

// ADBH_SEL
always @ ( * ) begin
	if(T_state[0]) begin
		if(BRANCH&BX)         ADBH_SEL = `ADBH_AOR;
		else if(BRANCH&BCC)   ADBH_SEL = {1'b1, `ADBH_BUFFER};
		else if(CONTROL&~RTS) ADBH_SEL = `ADBH_DIR;
		else ADBH_SEL = `ADBH_PCH;
	end else if(T_state[1]) begin
		ADBH_SEL = `ADBH_PCH;
	end else if(T_state[2]) begin
		if(STACK|BRK|JSR|RTS|RTI) ADBH_SEL = `ADBH_STACK;
		else if(ZPG|INDy)         ADBH_SEL = `ADBH_ZPG;
		else ADBH_SEL = `ADBH_PCH;
	end else if(T_state[3]) begin
		if(STACK|JSR|BRK|RTI|RTS) ADBH_SEL = `ADBH_STACK;
		else if(ZPGi|INDx|INDy)   ADBH_SEL = `ADBH_ZPG;
		else ADBH_SEL = {ABSi&COUT,`ADBH_DIR};
	end else if(T_state[4]) begin
		if(BRK|RTS|RTI) ADBH_SEL = `ADBH_STACK;
		else if(JSR)    ADBH_SEL = `ADBH_PCH;
		else if(ABSi)   ADBH_SEL = `ADBH_AOR;
		else if(INDx)   ADBH_SEL = `ADBH_ZPG;
		else ADBH_SEL = {~INDy|COUT,`ADBH_DIR};
	end else if(T_state[5]) begin
		if(BRK)       ADBH_SEL = `ADBH_VECTOR;
		else if(RTI)  ADBH_SEL = `ADBH_STACK;
		else if(INDy) ADBH_SEL = `ADBH_AOR;
		else ADBH_SEL = `ADBH_DIR;
	end else begin // SPECIAL
		ADBH_SEL = BRK? `ADBH_PCH : {1'b1, `ADBH_BUFFER};
	end
end
/**************************************************************************************************/

// ALU_FUNC
always @ ( * ) begin
	if(T_state[0]| ~|T_state) begin
		if(BRANCH&BCC)     ALU_FUNC = iDB7? `ALU_DEC : `ALU_INC;
		else if(BRANCH)    ALU_FUNC = `ALU_ADD;
		else if(STACK|BRK) ALU_FUNC = `ALU_PASS;
		else if(ORA)       ALU_FUNC = T_2? `ALU_ASL : `ALU_ORA;
		else if(AND)       ALU_FUNC = T_2? `ALU_ROL : `ALU_AND;
		else if(EOR)       ALU_FUNC = T_2? `ALU_LSR : `ALU_EOR;
		else if(ADC)       ALU_FUNC = T_2? `ALU_ROR : `ALU_ADD;
		else if(STORE)     ALU_FUNC = ABSy|T_2? `ALU_PASS : `ALU_DEC;
		else if(LOAD)      ALU_FUNC = `ALU_PASS;
		else if(CMP)       ALU_FUNC = T_2? `ALU_DEC : BLACK_SHEEP&T_3? `ALU_INC : `ALU_SUB;
		else ALU_FUNC = BLACK_SHEEP|T_2? `ALU_INC : `ALU_SUB;
	end else if(T_state[2]) begin
		if(BRK|JSR|STACK&~IR[5])    ALU_FUNC = `ALU_DEC;
		else if(RTI|RTS|STACK|INDy) ALU_FUNC = `ALU_INC;
		else if(ABS)                ALU_FUNC = `ALU_PASS;
		else ALU_FUNC = `ALU_ADD;
	end else if(T_state[3]) begin
		if(BRK|JSR)         ALU_FUNC = `ALU_DEC;
		else if(INDy)       ALU_FUNC = `ALU_ADD;
		else if(ABSi&~COUT) ALU_FUNC = `ALU_PASS;
		else ALU_FUNC = `ALU_INC;
	end else if(T_state[4]) begin
		if(RTI|INDy&COUT) ALU_FUNC = `ALU_INC;
		else if(BRK)      ALU_FUNC = `ALU_DEC;
		else ALU_FUNC = `ALU_PASS;
	end else begin
		ALU_FUNC = `ALU_PASS;
	end
end

// ALU_B_SEL
always @ ( * ) begin
	if (T_state[0]) begin
		if(BRANCH&~BCC) ALU_B_SEL = `ALUB_ADL;
		else ALU_B_SEL = `ALUB_iDB;
	end else if (T_state[2]) begin
		if(STACK|JSR|BRK|RTS|RTI) ALU_B_SEL = `ALUB_ADL;
		else ALU_B_SEL = `ALUB_iDB;
	end else if (T_state[3]) begin
		if(ABSi|INDy) ALU_B_SEL = `ALUB_iDB;
		else ALU_B_SEL = `ALUB_ADL;
	end else if (T_state[4]) begin
		if(BRK|RTI) ALU_B_SEL = `ALUB_ADL;
		else ALU_B_SEL = `ALUB_iDB;
	end else begin
		ALU_B_SEL = `ALUB_iDB;
	end
end

// CARRY_IN
always @ ( * ) begin
	if(T_state[0]) begin
		if(BRANCH)       CARRY_IN = 0;
		else if(CMP|T_3) CARRY_IN = 1;
		else CARRY_IN = PSR[0];
	end else if(T_state[2]) begin
		CARRY_IN = 0;
	end else if(T_state[3]) begin
		CARRY_IN = 0;
	end else begin
		CARRY_IN = PSR[0];
	end
end

/**************************************************************************************************/
// REQUEST_STORE
always @ ( * ) begin
	if(|T_state[1:0] | ~RESET_req) begin
		RnW = 1;
	end else if(T_state[2]) begin
		RnW = ~(ZPG&STORE|STACK&~IR[5]|JSR|BRK);
	end else if(T_state[3]) begin
		RnW = ~((ZPGi|ABS)&STORE|JSR|BRK);
	end else if(T_state[4]) begin
		RnW = ~(ABSi&STORE|BRK);
	end else if(T_state[5]) begin
		RnW = ~STORE;
	end else begin
		RnW = ~SD2;
	end
end

// NEXT_T , CLEAR_T
always @ ( * ) begin
	CLEAR_T = 0;
	if(T_state[0]) begin
		if(BRANCH&BCC)      NEXT_T = iDB7^COUT;
		else if(BRANCH&~BX) NEXT_T = branch_taken(IR[7:6]);
		else NEXT_T = 0;
	end else if(T_state[1]) begin
		NEXT_T = TWO_CYCLE&RESET_req&IRQ_req&NMI_req;
	end else if(T_state[2]) begin
		NEXT_T  = ZPG | ABS&CONTROL&~IR[5] | STACK&~IR[5];
		CLEAR_T = ZPG & RMW;
	end else if(T_state[3]) begin
		NEXT_T  = ABS&~CONTROL | ZPGi;
		CLEAR_T = NEXT_T & RMW;
		NEXT_T  = NEXT_T | STACK | ABSi&~(COUT|STORE|RMW);
	end else if(T_state[4]) begin
		NEXT_T  = ABSi | ABS | INDy&~(STORE|COUT);
		CLEAR_T = ABSi & RMW;
	end else if(T_state[5]) begin
		NEXT_T  = ~BRK;
	end else begin
		NEXT_T  = BRK|SD2;
	end
end


/**************************************************************************************************/

// N,Z,V,C enables
always @ ( * ) begin
	if(T_state[1] & ~(FLAGS|CONTROL|BRANCH)) begin
		N_en = T_1 & CMP | T_3 & (SBC|CMP) | ACC_en | iX_en | iY_en;
		Z_en = N_en | BIT;
		C_en = ACC | T_1 & (ADC|SBC|CMP) | T_3 & (SBC|CMP) & ~BLACK_SHEEP;
		V_en = T_1 & (SBC|ADC);
	end else if(SD2) begin
		V_en = 0; N_en = 1; Z_en = 1; C_en = ~IR[7];
	end else begin
		V_en = 0; N_en = 0; Z_en = 0; C_en = 0;
	end
end

// ACC_en, iX_en, iY_en
always @ ( * ) begin
	if(T_state[1] & ~(CONTROL|FLAGS|BRANCH) & READY) begin
		ACC_en = STACK&IR[6]&IR[5] | T_1&~(STORE|CMP) | ACC | BLACK_SHEEP&STORE&(IR[4]^IR[1]);
		iX_en = T_2 & LOAD | T_3 & SBC & BLACK_SHEEP | T_2 & CMP & BLACK_SHEEP;
		iY_en = T_3 & (LOAD | BLACK_SHEEP&(STORE|CMP));
	end else begin
		ACC_en = 0; iX_en = 0; iY_en = 0;
	end
end

// SP_en
always @ ( * ) begin
	if(~READY) begin
		SP_en = 0;
	end else if(T_state[0]) begin
		SP_en = STACK|STORE&ABSy&T_2;
	end else if(T_state[4]) begin
		SP_en = JSR|RTS;
	end else if(T_state[5]) begin
		SP_en = BRK|RTI;
	end else begin
		SP_en = 0;
	end
end

// PC_en
always @ ( * ) begin
	if(~READY) begin
		PC_en = 0;
	end else if(T_state[0]) begin
		PC_en = 1;
	end else if(T_state[1]) begin
		PC_en = ~ONE_BYTE;
	end else if(T_state[2]) begin
		PC_en = ABS|ABSi;
	end else if(T_state[5]) begin
		PC_en = BRK|RTS;
	end else begin
		PC_en = 0;
	end
end

// AOR_en, DIR_en
always @ ( * ) begin
	if(~READY) begin
		AOR_en = 0;
		DIR_en = 0;
	end else if(T_state[2]) begin
		AOR_en = 1;
		DIR_en = ~JSR;
	end else if(T_state[3]) begin
		AOR_en = ~STACK;
		DIR_en = ~JSR;
	end else if(T_state[5]) begin
		AOR_en = ~JSR;
		DIR_en = ~JSR;
	end else begin
		AOR_en = 1;
		DIR_en = 1;
	end
end
/**************************************************************************************************/
function branch_taken;
input [1:0] CC;
begin
case (CC)
	2'b00: branch_taken = PSR[7] ~^ IR[5];
	2'b01: branch_taken = PSR[6] ~^ IR[5];
	2'b10: branch_taken = PSR[0] ~^ IR[5];
	2'b11: branch_taken = PSR[1] ~^ IR[5];
	default: branch_taken = 1'bx;
endcase
end
endfunction

endmodule //Decode_6502
