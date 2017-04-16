`include "MOS6502.vh"

module MOS6502_Decode (
	input [7:0] IR,
	input [3:0] T_state,
	input [7:0] PSR,
	input [7:0] DIR,
	input iDB7,
	input COUT,
	input nNMI_req,
	input nIRQ_req,
	input nRESET_req,
	input READY,

	output reg [2:0] iDB_SEL,
	output reg [2:0] SB_SEL,
	output reg [2:0] ADBL_SEL,
	output reg [2:0] ADBH_SEL,
	output reg [3:0] ALU_FUNC,
	output reg ALU_B_SEL,
	output reg CARRY_IN,
	output reg RnW,
	output reg NEXT_T,
	output reg NEXT_S,
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
	output PLP,
	output PLA,
	output RTI,
	output BRK,
	output BIT,
	output FLAGS,
	output decimal_en);
/*--------------------------------------------------------------------------------------*/

	assign PLP = IR == 8'h28;
	assign PLA = IR == 8'h68;
	assign RTI = IR == 8'h40;
	assign BRK = IR == 8'h00;
	assign BIT = IR[7:5] == 3'b001 && ~IR[4] && IR[2] && IR[1:0] == 2'b00;
	assign decimal_en = T_state == `T0 && (IR[6]&IR[5]&IR[0]) && PSR[3];
	assign FLAGS = IR[7:5] != 3'b100 && IR[4:0] == 5'b11000;

	// PREDECODE
	wire ONE_BYTE  = DIR[3] & ~(DIR[2]|DIR[0]);
	wire TWO_CYCLE = ~DIR[4] & (DIR[3]|~DIR[0]) & ~DIR[2] & (DIR[7]|DIR[1]|DIR[0]) // IMM NOT STACK
					| DIR[4] & ~DIR[2] & ~DIR[0]; // BRANCH AND FLAGS + (SOME TRANSFERS)
/*--------------------------------------------------------------------------------------*/

always @ ( * ) begin
	iDB_SEL = `iDB_DIR;
	case (T_state)
	`T0:	casex(IR)
			8'b0xxx_1010: iDB_SEL = `iDB_ACC;
			8'b1xxx_10x0: iDB_SEL = `iDB_SB;
			endcase
	`T0BCC:	iDB_SEL = `iDB_ABH;
	`T1:	iDB_SEL = `iDB_SB;
	`T2:	casex(IR)
			8'b00x0_1000: iDB_SEL = `iDB_PSR;
			8'b01x0_1000: iDB_SEL = `iDB_ACC;
			8'bx0xx_0000: iDB_SEL = `iDB_PCH;
			8'bxxx0_01xx: iDB_SEL = `iDB_SB;
			endcase
	`T3:	casex(IR)
			8'bx0xx_0000: iDB_SEL = `iDB_PCL;
			8'bxxx1_01xx,
			8'bxxx0_11xx: iDB_SEL = `iDB_SB;
			endcase
	`T4:	casex(IR)
			8'bx00x_0000: iDB_SEL = `iDB_PSR;
			8'bxxx1_1xxx: iDB_SEL = `iDB_ACC;
			endcase
	`T5:	casex(IR)
			8'bxxxx_xxx1: iDB_SEL = `iDB_ACC;
			endcase
	`TSD2:	iDB_SEL = `iDB_SB;
	endcase
end

always @ ( * )
	case(T_state)
	`T0:	casex(IR)
			8'b0xx0_1000: SB_SEL = `SB_AOR;
			8'bxxx1_0000: SB_SEL = `SB_iDB;
			8'bxxxx_xxx1,
			8'b1010_10xx,
			8'b0010_x100: SB_SEL = `SB_ACC;
			8'b101x_xx10: SB_SEL = `SB_SP;
			8'bxxxx_xx1x,
			8'b111x_xx00: SB_SEL = `SB_iX;
			default:      SB_SEL = `SB_iY;
			endcase
	`T0BCC,
	`T0BX:	SB_SEL = `SB_iDB;
	`T2:	casex(IR)
			8'bxxx0_01x1: SB_SEL = `SB_ACC;
			8'bxxx1_10xx,
			8'bxxx0_0100,
			8'b10x1_xx1x: SB_SEL = `SB_iY;
			default:      SB_SEL = `SB_iX;
			endcase
	`T3:	casex(IR)
			8'bxxx1_00xx,
			8'bxxxx_xx00: SB_SEL = `SB_iY;
			8'bxxxx_xxx1: SB_SEL = `SB_ACC;
			default:      SB_SEL = `SB_iX;
			endcase
	default: SB_SEL = `SB_AOR;
	endcase

always @ ( * )
	case (T_state)
	`T0:	casex(IR)
			8'b0110_0000: begin ADBH_SEL = `ADBH_PCH; ADBL_SEL = `ADBL_PCL; end
			8'b0xx0_0000,
			8'b01x0_1100: begin ADBH_SEL = `ADBH_DIR; ADBL_SEL = `ADBL_AOR; end
			default:      begin ADBH_SEL = `ADBH_PCH; ADBL_SEL = `ADBL_PCL; end
			endcase
	`T0BCC:	begin ADBH_SEL = `ADBH_BUFFER;ADBL_SEL = `ADBL_AOR;    end
	`T0BX:	begin ADBH_SEL = `ADBH_AOR;   ADBL_SEL = `ADBL_BUFFER; end
	`T1:	begin ADBH_SEL = `ADBH_PCH;   ADBL_SEL = `ADBL_PCL;    end
	`T2:	casex(IR)
			8'b0xx0_x000: begin ADBH_SEL = `ADBH_STACK;ADBL_SEL = `ADBL_STACK; end
			8'bxxx0_01xx,
			8'bxxx1_00xx: begin ADBH_SEL = `ADBH_ZPG;ADBL_SEL = `ADBL_DIR; end
			default:      begin ADBH_SEL = `ADBH_PCH;ADBL_SEL = `ADBL_PCL; end
			endcase
	`T3:	begin
			ADBL_SEL = `ADBL_AOR;
			casex(IR)
			8'b0xx0_x000: ADBH_SEL = `ADBH_STACK;
			8'bxxxx_00xx,
			8'bxxx1_01xx: ADBH_SEL = `ADBH_ZPG;
			default:      ADBH_SEL = `ADBH_DIR;
			endcase
			end
	`T4:	begin
			casex(IR)
			8'bx01x_0000: ADBL_SEL = `ADBL_PCL;
			8'bxxx1_1xxx: ADBL_SEL = `ADBL_BUFFER;
			default:      ADBL_SEL = `ADBL_AOR;
			endcase
			casex(IR)
			8'bx01x_0000: ADBH_SEL = `ADBH_PCH;
			8'bxxxx_0000: ADBH_SEL = `ADBH_STACK;
			8'bxxx1_1xxx: ADBH_SEL = `ADBH_AOR;
			8'bxxx0_00xx: ADBH_SEL = `ADBH_ZPG;
			8'b0xx0_1xxx: ADBH_SEL = `ADBH_BUFFER;
			default:      ADBH_SEL = `ADBH_DIR;
			endcase
			end
	`T5:	begin
			casex(IR)
			8'bx00x_0000: ADBL_SEL = ~nRESET_req?`ADBL_RESET:~nNMI_req?`ADBL_NMI:`ADBL_IRQ;
			8'bxxx1_0xxx: ADBL_SEL = `ADBL_BUFFER;
			default:      ADBL_SEL = `ADBL_AOR;
			endcase
			casex(IR)
			8'bx00x_0000: ADBH_SEL = `ADBH_VECTOR;
			8'bx10x_0000: ADBH_SEL = `ADBH_STACK;
			8'bxxx1_00xx: ADBH_SEL = `ADBH_AOR;
			default:      ADBH_SEL = `ADBH_DIR;
			endcase
			end
	`TVEC:	begin ADBH_SEL = `ADBH_PCH;ADBL_SEL = `ADBL_PCL; end
	default:begin ADBH_SEL = `ADBH_BUFFER;ADBL_SEL = `ADBL_BUFFER; end
	endcase

/****************************************************************************************/

always @ ( * )
	case (T_state)
		`T0,
		`TSD1:	casex(IR)
				8'b1000_1000: ALU_FUNC = `ALU_DEC;
				8'b11x0_1000: ALU_FUNC = `ALU_INC;
				8'bxxx1_0000: ALU_FUNC = `ALU_ADD;
				8'b0xx0_1000: ALU_FUNC = `ALU_PASS;
				8'b000x_xxxx: ALU_FUNC = IR[1]? `ALU_ASL : `ALU_ORA;
				8'b001x_xxxx: ALU_FUNC = IR[1]? `ALU_ROL : `ALU_AND;
				8'b010x_xxxx: ALU_FUNC = IR[1]? `ALU_LSR : `ALU_EOR;
				8'b011x_xxxx: ALU_FUNC = IR[1]? `ALU_ROR : `ALU_ADD;
				8'b10xx_xxxx: ALU_FUNC = `ALU_PASS;
				8'b110x_xxxx: ALU_FUNC = IR[1]? `ALU_DEC : `ALU_SUB;
				default:      ALU_FUNC = IR[1]? `ALU_INC : `ALU_SUB;
				endcase
		`T0BCC: ALU_FUNC = iDB7? `ALU_DEC : `ALU_INC;
		`T2:	casex(IR)
				8'bx0xx_00x0,8'bxx0x_10x0: ALU_FUNC = `ALU_DEC;
				8'bx1xx_00x0,8'bxx1x_10x0: ALU_FUNC = `ALU_INC;
				8'bxxx1_00xx: ALU_FUNC = `ALU_INC;
				8'bxxx0_11xx: ALU_FUNC = `ALU_PASS;
				default:      ALU_FUNC = `ALU_ADD;
				endcase
		`T3:	casex(IR)
				8'bx0xx_00x0: ALU_FUNC = `ALU_DEC;
				8'bxxx1_00xx: ALU_FUNC = `ALU_ADD;
				8'bxxx1_1xxx: ALU_FUNC = COUT? `ALU_INC : `ALU_PASS;
				default:      ALU_FUNC = `ALU_INC;
				endcase
		`T4:	casex(IR)
				8'bxx0x_x0x0: ALU_FUNC = IR[6]? `ALU_INC : `ALU_DEC;
				8'bxxx1_00xx: ALU_FUNC = COUT?  `ALU_INC : `ALU_PASS;
				default:      ALU_FUNC = `ALU_PASS;
				endcase
		default: ALU_FUNC = `ALU_PASS;
	endcase

always @ ( * ) begin
	ALU_B_SEL = `ALUB_iDB;
	case (T_state)
		`T0:	casex(IR) 8'bxxx1_0000: ALU_B_SEL = `ALUB_ADL; endcase
		`T2:	casex(IR) 8'bxxxx_x0x0: ALU_B_SEL = `ALUB_ADL; endcase
		`T3:	casex(IR) 8'bxxx0_xxxx: ALU_B_SEL = `ALUB_ADL; endcase
		`T4:	casex(IR) 8'bxx0x_x0x0: ALU_B_SEL = `ALUB_ADL; endcase
	endcase
end

always @ ( * ) begin
	CARRY_IN = PSR[0];
	case(T_state)
	`T0:	casex(IR)
			8'bxxxx_xx00: CARRY_IN = ~IR[4];
			8'b110x_xxxx: CARRY_IN = 1;
			endcase
	`T2,`T3:CARRY_IN = 0;
	endcase
end

/****************************************************************************************/

always @ ( * ) begin
	RnW = 1;
	if(nRESET_req) case (T_state)
		`T2:	casex(IR) 8'bx0xx_0000,8'bxx0x_1000,8'b1000_01xx: RnW = 0; endcase
		`T3:	casex(IR) 8'b1001_01xx,8'b1000_11xx,8'bx0xx_0000: RnW = 0; endcase
		`T4:	casex(IR) 8'b1001_1xxx,8'bx00x_0000: RnW = 0; endcase
		`T5:	casex(IR) 8'b100x_xxxx: RnW = 0; endcase
		`TSD2:	RnW = 0;
	endcase
end

always @ ( * ) begin
	NEXT_T = 0;
	case (T_state)
		`T0:	casex(IR) 8'bxxx1_0000: NEXT_T = branch_taken(IR[7:6]); endcase
		`T0BCC:	NEXT_T = iDB7^COUT;
		`T1:	NEXT_T = TWO_CYCLE&(nRESET_req&nIRQ_req&nNMI_req);
		`T2:	casex(IR) 8'bxxx0_01xx,8'b0x00_1x00: NEXT_T = 1; endcase
		`T3:	casex(IR) 8'b1001_1xx1,8'b0110_1100: NEXT_T = 0;
						  8'bxxx1_01xx,8'bxxxx_10x0,8'bxxx0_11xx: NEXT_T = 1;
						  8'bxxx1_111x: NEXT_T = IR[7]&~IR[6]&~COUT;
						  8'bxxx1_1xxx: NEXT_T = ~COUT;
						  endcase
		`T4:	casex(IR) 8'bxxx1_1xxx,8'bxxx0_1xxx: NEXT_T = 1;
						  8'b1001_00xx: NEXT_T = 0;
						  8'bxxx1_0xxx: NEXT_T = ~COUT;
						  endcase
		`T5:	NEXT_T = ~BRK;
		`TVEC,
		`TSD2:	NEXT_T = 1;
	endcase
end

always @ ( * ) begin
	NEXT_S = 0;
	case (T_state)
		`T2:	casex(IR) 8'b0xx0_011x,8'b11x0_011x: NEXT_S = 1; endcase
		`T3:	casex(IR) 8'b0xx1_011x,8'b11x1_011x: NEXT_S = 1;
						  8'b0xx0_111x,8'b11x0_111x: NEXT_S = 1; endcase
		`T4:	casex(IR) 8'b0xx1_111x,8'b11x1_111x: NEXT_S = 1; endcase
	endcase
end

/****************************************************************************************/

always @ ( * ) begin
	C_en = 0; Z_en = 0; V_en = 0; N_en = 0;
	case (T_state)
		`T1:	casex(IR)
				8'bx11x_xxx1: begin V_en = 1; C_en = 1; N_en = 1; Z_en = 1; end
				8'b0xxx_1010,8'b110x_xxx1,8'b11x0_0000,8'b11xx_x100: begin C_en = 1; N_en = 1; Z_en = 1; end
				8'b11x0_x000,8'b0xxx_xxx1,8'b1010_xxxx,8'b1011_x1xx,
				8'b1011_x01x,8'b1011_x001,8'b1100_1010,
				8'b1001_1000,8'b1000_10xx: begin N_en = 1; Z_en = 1; end
				default: Z_en = BIT;
				endcase
		`TSD2:	begin N_en = 1; Z_en = 1; C_en = ~IR[7]; end
	endcase
end

always @ ( * ) begin
	ACC_en = 0; iX_en = 0; iY_en = 0;
	if(READY) case (T_state)
		`T1: begin
			casex(IR) 8'b0110_1000,8'b1000_1010,8'b1001_1000,
					  8'b0xxx_xxx1,8'b1x1x_xxx1,8'b0xxx_1010: ACC_en = 1;
			endcase
			casex(IR) 8'b1110_1000,8'b1100_1010,8'b101x_xx1x: iX_en = 1; endcase
			casex(IR) 8'b1010_xx00,8'b1011_x100,8'b1x00_1000: iY_en = 1; endcase
			end
	endcase
end

always @ ( * ) begin
	SP_en = 0;
	if(READY) case (T_state)
	`T0:	casex(IR) 8'b0xx0_1000,8'b1001_1010: SP_en = 1; endcase
	`T4:	casex(IR) 8'bxx1x_0000: SP_en = 1; endcase
	`T5:	casex(IR) 8'bxx0x_0000: SP_en = 1; endcase
	endcase
end

always @ ( * ) begin
	PC_en = 0;
	if(READY) case (T_state)
		`T0,`T0BCC,`T0BX: PC_en = 1;
		`T1: PC_en = ~ONE_BYTE;
		`T2: casex(IR) 8'bxxx1_1xxx,8'bxxx0_11xx: PC_en = 1; endcase
		`T5: casex(IR) 8'bx00x_0000,8'bx11x_0000: PC_en = 1; endcase
	endcase
end

always @ ( * ) begin
	AOR_en = 0;
	DIR_en = 0;
	if(READY) case (T_state)
		`T2:	begin DIR_en = IR != 8'h20; AOR_en = 1; end
		`T3:	begin DIR_en = IR != 8'h20; AOR_en = IR[4:2] != 3'b010; end
		`T5:	begin DIR_en = IR != 8'h20; AOR_en = IR != 8'h20; end
		default:begin DIR_en = 1; AOR_en = 1; end
	endcase
end

/****************************************************************************************/
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

endmodule
