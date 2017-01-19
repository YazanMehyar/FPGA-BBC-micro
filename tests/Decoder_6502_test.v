module Decoder_6502_test ();

	// input
	reg [7:0] IR;
	reg [7:0] PSR;
	reg [7:0] DIR;
	reg [5:0] T_state;
	reg iDB7;
	reg SD2;
	reg COUT;
	reg BX;
	reg BCC;
	reg NMI_req;
	reg RESET_req;
	reg READY;

	// output
	wire [2:0] iDB_SEL;
	wire [2:0] SB_SEL;
	wire [3:0] ADBL_SEL;
	wire [3:0] ADBH_SEL;
	wire [3:0] ALU_FUNC;
	wire ALU_B_SEL;
	wire CARRY_IN;
	wire RnW;
	wire NEXT_T;
	wire CLEAR_T;
	wire ACC_en;
	wire iX_en;
	wire iY_en;
	wire SP_en;
	wire PC_en;
	wire AOR_en;
	wire DIR_en;
	wire N_en;
	wire Z_en;
	wire C_en;
	wire V_en;
	wire FLAGS;
	wire PLP;
	wire RTI;
	wire BIT;
	wire BRK;

	Decode_6502 d(
		.IR(IR),
		.T_state(T_state),
		.PSR(PSR),
		.DIR(DIR),
		.iDB7(iDB7),
		.SD2(SD2),
		.COUT(COUT),
		.BX(BX),
		.BCC(BCC),
		.NMI_req(~NMI_req),
		.RESET_req(~RESET_req),
		.READY(READY),

		.iDB_SEL(iDB_SEL),
		.SB_SEL(SB_SEL),
		.ADBL_SEL(ADBL_SEL),
		.ADBH_SEL(ADBH_SEL),
		.ALU_FUNC(ALU_FUNC),
		.ALU_B_SEL(ALU_B_SEL),
		.CARRY_IN(CARRY_IN),
		.RnW(RnW),
		.NEXT_T(NEXT_T),
		.CLEAR_T(CLEAR_T),
		.N_en(N_en),
		.Z_en(Z_en),
		.C_en(C_en),
		.V_en(V_en),
		.FLAGS(FLAGS),
		.PLP(PLP),
		.RTI(RTI),
		.BIT(BIT),
		.BRK(BRK),
		.ACC_en(ACC_en),
		.iX_en(iX_en),
		.iY_en(iY_en),
		.SP_en(SP_en),
		.PC_en(PC_en),
		.AOR_en(AOR_en),
		.DIR_en(DIR_en));

reg [160:0] Instruction_name [0:255];
reg [64:0] ADBL_SEL_name [0:15];
reg [64:0] ADBH_SEL_name [0:15];
reg [64:0] iDB_SEL_name [0:5];
reg [64:0] SB_SEL_name [0:5];
reg [64:0] ALU_FUNC_name [0:11];
initial begin
Instruction_name[8'h00] = "BRK";
Instruction_name[8'h01] = "ORA - (Indirect,X)";
Instruction_name[8'h05] = "ORA - Zero Page";
Instruction_name[8'h06] = "ASL - Zero Page";
Instruction_name[8'h08] = "PHP";
Instruction_name[8'h09] = "ORA - Immediate";
Instruction_name[8'h0A] = "ASL - Accumulator";
Instruction_name[8'h0D] = "ORA - Absolute";
Instruction_name[8'h0E] = "ASL - Absolute";
Instruction_name[8'h10] = "BPL";
Instruction_name[8'h11] = "ORA - (Indirect),Y";
Instruction_name[8'h15] = "ORA - Zero Page,X";
Instruction_name[8'h16] = "ASL - Zero Page,X";
Instruction_name[8'h18] = "CLC";
Instruction_name[8'h19] = "ORA - Absolute,Y";
Instruction_name[8'h1D] = "ORA - Absolute,X";
Instruction_name[8'h1E] = "ASL - Absolute,X";
Instruction_name[8'h40] = "RTI";
Instruction_name[8'h41] = "EOR - (Indirect,X)";
Instruction_name[8'h45] = "EOR - Zero Page";
Instruction_name[8'h46] = "LSR - Zero Page";
Instruction_name[8'h48] = "PHA";
Instruction_name[8'h49] = "EOR - Immediate";
Instruction_name[8'h4A] = "LSR - Accumulator";
Instruction_name[8'h4C] = "JMP - Absolute";
Instruction_name[8'h4D] = "EOR - Absolute";
Instruction_name[8'h4E] = "LSR - Absolute";
Instruction_name[8'h50] = "BVC";
Instruction_name[8'h51] = "EOR - (Indirect),Y";
Instruction_name[8'h55] = "EOR - Zero Page,X";
Instruction_name[8'h56] = "LSR - Zero Page,X";
Instruction_name[8'h58] = "CLI";
Instruction_name[8'h59] = "EOR - Absolute,Y";
Instruction_name[8'h5D] = "EOR - Absolute,X";
Instruction_name[8'h5E] = "LSR - Absolute,X";
Instruction_name[8'h81] = "STA - (Indirect,X)";
Instruction_name[8'h84] = "STY - Zero Page";
Instruction_name[8'h85] = "STA - Zero Page";
Instruction_name[8'h86] = "STX - Zero Page";
Instruction_name[8'h88] = "DEY";
Instruction_name[8'h8A] = "TXA";
Instruction_name[8'h8C] = "STY - Absolute";
Instruction_name[8'h8D] = "STA - Absolute";
Instruction_name[8'h8E] = "STX - Absolute";
Instruction_name[8'h90] = "BCC";
Instruction_name[8'h91] = "STA - (Indirect),Y";
Instruction_name[8'h94] = "STY - Zero Page,X";
Instruction_name[8'h95] = "STA - Zero Page,X";
Instruction_name[8'h96] = "STX - Zero Page,Y";
Instruction_name[8'h98] = "TYA";
Instruction_name[8'h99] = "STA - Absolute,Y";
Instruction_name[8'h9A] = "TXS";
Instruction_name[8'h9D] = "STA - Absolute,X";
Instruction_name[8'hC0] = "Cpy - Immediate";
Instruction_name[8'hC1] = "CMP - (Indirect,X)";
Instruction_name[8'hC4] = "CPY - Zero Page";
Instruction_name[8'hC5] = "CMP - Zero Page";
Instruction_name[8'hC6] = "DEC - Zero Page";
Instruction_name[8'hC8] = "INY";
Instruction_name[8'hC9] = "CMP - Immediate";
Instruction_name[8'hCA] = "DEX";
Instruction_name[8'hCC] = "CPY - Absolute";
Instruction_name[8'hCD] = "CMP - Absolute";
Instruction_name[8'hCE] = "DEC - Absolute";
Instruction_name[8'hD0] = "BNE";
Instruction_name[8'hD1] = "CMP   (Indirect),Y";
Instruction_name[8'hD5] = "CMP - Zero Page,X";
Instruction_name[8'hD6] = "DEC - Zero Page,X";
Instruction_name[8'hD8] = "CLD";
Instruction_name[8'hD9] = "CMP - Absolute,Y";
Instruction_name[8'hDD] = "CMP - Absolute,X";
Instruction_name[8'hDE] = "DEC - Absolute,X";
Instruction_name[8'h20] = "JSR";
Instruction_name[8'h21] = "AND - (Indirect,X)";
Instruction_name[8'h24] = "BIT - Zero Page";
Instruction_name[8'h25] = "AND - Zero Page";
Instruction_name[8'h26] = "ROL - Zero Page";
Instruction_name[8'h28] = "PLP";
Instruction_name[8'h29] = "AND - Immediate";
Instruction_name[8'h2A] = "ROL - Accumulator";
Instruction_name[8'h2C] = "BIT - Absolute";
Instruction_name[8'h2D] = "AND - Absolute";
Instruction_name[8'h2E] = "ROL - Absolute";
Instruction_name[8'h30] = "BMI";
Instruction_name[8'h31] = "AND - (Indirect),Y";
Instruction_name[8'h35] = "AND - Zero Page,X";
Instruction_name[8'h36] = "ROL - Zero Page,X";
Instruction_name[8'h38] = "SEC";
Instruction_name[8'h39] = "AND - Absolute,Y";
Instruction_name[8'h3D] = "AND - Absolute,X";
Instruction_name[8'h3E] = "ROL - Absolute,X";
Instruction_name[8'h60] = "RTS";
Instruction_name[8'h61] = "ADC - (Indirect,X)";
Instruction_name[8'h65] = "ADC - Zero Page";
Instruction_name[8'h66] = "ROR - Zero Page";
Instruction_name[8'h68] = "PLA";
Instruction_name[8'h69] = "ADC - Immediate";
Instruction_name[8'h6A] = "ROR - Accumulator";
Instruction_name[8'h6C] = "JMP - Indirect";
Instruction_name[8'h6D] = "ADC - Absolute";
Instruction_name[8'h6E] = "ROR - Absolute";
Instruction_name[8'h70] = "BVS";
Instruction_name[8'h71] = "ADC - (Indirect),Y";
Instruction_name[8'h75] = "ADC - Zero Page,X";
Instruction_name[8'h76] = "ROR - Zero Page,X";
Instruction_name[8'h78] = "SEI";
Instruction_name[8'h79] = "ADC - Absolute,Y";
Instruction_name[8'h7D] = "ADC - Absolute,X";
Instruction_name[8'h7E] = "ROR - Absolute,X";
Instruction_name[8'hA0] = "LDY - Immediate";
Instruction_name[8'hA1] = "LDA - (Indirect,X)";
Instruction_name[8'hA2] = "LDX - Immediate";
Instruction_name[8'hA4] = "LDY - Zero Page";
Instruction_name[8'hA5] = "LDA - Zero Page";
Instruction_name[8'hA6] = "LDX - Zero Page";
Instruction_name[8'hA8] = "TAY";
Instruction_name[8'hA9] = "LDA - Immediate";
Instruction_name[8'hAA] = "TAX";
Instruction_name[8'hAC] = "LDY - Absolute";
Instruction_name[8'hAD] = "LDA - Absolute";
Instruction_name[8'hAE] = "LDX - Absolute";
Instruction_name[8'hB0] = "BCS";
Instruction_name[8'hB1] = "LDA - (Indirect),Y";
Instruction_name[8'hB4] = "LDY - Zero Page,X";
Instruction_name[8'hB5] = "LDA - Zero Page,X";
Instruction_name[8'hB6] = "LDX - Zero Page,Y";
Instruction_name[8'hB8] = "CLV";
Instruction_name[8'hB9] = "LDA - Absolute,Y";
Instruction_name[8'hBA] = "TSX";
Instruction_name[8'hBC] = "LDY - Absolute,X";
Instruction_name[8'hBD] = "LDA - Absolute,X";
Instruction_name[8'hBE] = "LDX - Absolute,Y";
Instruction_name[8'hE0] = "CPX - Immediate";
Instruction_name[8'hE1] = "SBC - (Indirect,X)";
Instruction_name[8'hE4] = "CPX - Zero Page";
Instruction_name[8'hE5] = "SBC - Zero Page";
Instruction_name[8'hE6] = "INC - Zero Page";
Instruction_name[8'hE8] = "INX";
Instruction_name[8'hE9] = "SBC - Immediate";
Instruction_name[8'hEA] = "NOP";
Instruction_name[8'hEC] = "CPX - Absolute";
Instruction_name[8'hED] = "SBC - Absolute";
Instruction_name[8'hEE] = "INC - Absolute";
Instruction_name[8'hF0] = "BEQ";
Instruction_name[8'hF1] = "SBC - (Indirect),Y";
Instruction_name[8'hF5] = "SBC - Zero Page,X";
Instruction_name[8'hF6] = "INC - Zero Page,X";
Instruction_name[8'hF8] = "SED";
Instruction_name[8'hF9] = "SBC - Absolute,Y";
Instruction_name[8'hFD] = "SBC - Absolute,X";
Instruction_name[8'hFE] = "INC - Absolute,X";

ADBL_SEL_name[4'h0] = "AOR";
ADBL_SEL_name[4'h1] = "PCL";
ADBL_SEL_name[4'h2] = "DIR";
ADBL_SEL_name[4'h3] = "IRQ";
ADBL_SEL_name[4'h4] = "NMI";
ADBL_SEL_name[4'h5] = "RESET";
ADBL_SEL_name[4'h6] = "STACK";
ADBL_SEL_name[4'h7] = "BUFFER";
ADBL_SEL_name[4'h8] = "B_AOR";
ADBL_SEL_name[4'h9] = "B_PCL";
ADBL_SEL_name[4'hA] = "B_DIR";
ADBL_SEL_name[4'hB] = "B_IRQ";
ADBL_SEL_name[4'hC] = "B_NMI";
ADBL_SEL_name[4'hD] = "B_RESET";
ADBL_SEL_name[4'hE] = "B_STACK";
ADBL_SEL_name[4'hF] = "B_BUFFER";

ADBH_SEL_name[4'h0] = "PCH";
ADBH_SEL_name[4'h1] = "AOR";
ADBH_SEL_name[4'h2] = "DIR";
ADBH_SEL_name[4'h3] = "ZPG";
ADBH_SEL_name[4'h4] = "STACK";
ADBH_SEL_name[4'h5] = "VECTOR";
ADBH_SEL_name[4'h7] = "BUFFER";
ADBH_SEL_name[4'h8] = "B_PCH";
ADBH_SEL_name[4'h9] = "B_AOR";
ADBH_SEL_name[4'hA] = "B_DIR";
ADBH_SEL_name[4'hB] = "B_ZPG";
ADBH_SEL_name[4'hC] = "B_STACK";
ADBH_SEL_name[4'hD] = "B_VECTOR";
ADBH_SEL_name[4'hF] = "B_BUFFER";

iDB_SEL_name[0] = "PCL";
iDB_SEL_name[1] = "PCH";
iDB_SEL_name[2] = "SB";
iDB_SEL_name[3] = "DIR";
iDB_SEL_name[4] = "ACC";
iDB_SEL_name[5] = "PSR";

SB_SEL_name[0] = "iDB";
SB_SEL_name[1] = "ACC";
SB_SEL_name[2] = "iX";
SB_SEL_name[3] = "iY";
SB_SEL_name[4] = "SP";
SB_SEL_name[5] = "AOR";

ALU_FUNC_name[0]	= "ADD";
ALU_FUNC_name[1]	= "SUB";
ALU_FUNC_name[2]	= "AND";
ALU_FUNC_name[3]	= "ORA";
ALU_FUNC_name[4]	= "EOR";
ALU_FUNC_name[5]	= "PASS";
ALU_FUNC_name[6]	= "INC";
ALU_FUNC_name[7]	= "DEC";
ALU_FUNC_name[8]	= "LSR";
ALU_FUNC_name[9]	= "ASL";
ALU_FUNC_name[10]	= "ROR";
ALU_FUNC_name[11]	= "ROL";
end

/**************************************************************************************************/

// TESTED
function isValid;
input [7:0] IR;
begin
	if(&IR[1:0]) isValid = 0;
	else if(IR[3:0] == 4'h0) begin
		isValid = IR[7:4] != 4'h8;
	end else if(IR[3:0] == 4'h2) begin
		isValid = IR[7:4] == 4'hA;
	end else if(IR[3:0] == 4'h4) begin
		if(~IR[7])
			isValid = IR[7:4] == 4'h2;
		else
			isValid = IR[7:4] != 4'hD && IR[7:4] != 4'hF;
	end else if(IR[3:0] == 4'h9) begin
		isValid = IR[7:4] != 4'h8;
	end else if(IR[3:0] == 4'hA) begin
		if(~IR[7])
			isValid = ~IR[4];
		else
			isValid = IR[7:4] != 4'hD && IR[7:4] != 4'hF;
	end else if(IR[3:0] == 4'hC) begin
		if(~IR[7])
			isValid = ~IR[4] && IR[7:4] != 4'h0;
		else
			isValid = IR[7:4] != 4'hD && IR[7:4] != 4'hF && IR[7:4] != 4'h9;
	end else if(IR[3:0] == 4'hE) begin
		isValid = IR[7:4] != 4'h9;
	end else isValid = 1;
end
endfunction

task strobe_signals;
begin
	$display("======================================================");
	$display("T_state: %b \t |  %H - %-19s", T_state, IR, Instruction_name[IR]);
	$display("======================================================");
	$display("|  ADBL_SEL | ADBH_SEL | iDB_SEL | SB_SEL | ALU_FUNC |");
	$display("|  %8s | %8s | %7s | %6s | %8s |", ADBL_SEL_name[ADBL_SEL],
													ADBH_SEL_name[ADBH_SEL],
													iDB_SEL_name[iDB_SEL],
													SB_SEL_name[SB_SEL],
													ALU_FUNC_name[ALU_FUNC]);
	$display("------------------------------------------------------");
	$display("| ALU_B_SEL | CARRY_IN |   RnW   | NEXT_T | CLEAR_T  |");
	$display("|  %8s | %8s | %7s | %6s | %8s |", ALU_B_SEL? "iDB":"ADL",
													CARRY_IN? "YES":"no",
													RnW?      "read":"WRITE",
													NEXT_T?   "YES":"no",
													CLEAR_T?  "YES":"no");
	$display("------------------------------------------------------");
	$display("Register Enables: %3s %3s %3s %3s %3s %3s %3s ",
														ACC_en? "ACC":"---",
														iX_en?  "iX":"---",
														iY_en?  "iY":"---",
														SP_en?  "SP":"---",
														PC_en?  "PC":"---",
														AOR_en? "AOR":"---",
														DIR_en? "DIR":"---");
	$display("------------------------------------------------------");
	$display("Flags enabled: %1s %1s %1s %1s | Special: %2s %2s %2s %2s %2s",
												N_en? "N":"-", V_en? "V":"-",
												C_en? "C":"-", Z_en? "Z":"-",
												BRK? "BK":"--", BIT? "BT":"--",
												RTI? "RT":"--", PLP? "PL":"--",
												FLAGS? "F!":"--");
end
endtask

reg [38:0] saved_state, current_state;
task save_state;
begin
	saved_state = {iDB_SEL,SB_SEL,ADBL_SEL,ADBH_SEL,ALU_FUNC,
					ALU_B_SEL,CARRY_IN,RnW,NEXT_T,CLEAR_T,
					ACC_en,iX_en,iY_en,SP_en,PC_en,AOR_en,DIR_en,
					N_en,Z_en,C_en,V_en,FLAGS,PLP,RTI,BIT,BRK};
end
endtask

task compare_state;
begin
	current_state = {iDB_SEL,SB_SEL,ADBL_SEL,ADBH_SEL,ALU_FUNC,
					ALU_B_SEL,CARRY_IN,RnW,NEXT_T,CLEAR_T,
					ACC_en,iX_en,iY_en,SP_en,PC_en,AOR_en,DIR_en,
					N_en,Z_en,C_en,V_en,FLAGS,PLP,RTI,BIT,BRK};

	if(saved_state != current_state) begin
		$display("\nERROR!");
		$display("Saved:   %h\nCurrent: %h\nDiff:    %h", saved_state, current_state,
															saved_state ^ current_state);
		strobe_signals;
	end
end
endtask
/**************************************************************************************************/

integer timer;

initial begin

PSR = 8'h00;
BX  = 0;
BCC = 0;
iDB7 = 0;
SD2  = 0;
COUT = 0;
READY = 0;
NMI_req   = 0;
RESET_req = 0;

// simulate normal operation
DIR = 8'h00;
IR  = 8'h00;
T_state = 6'h01;
READY = 1;
RESET_req = 1;
NMI_req = 1;

// timer = 2;
// while(timer < 6) begin
// 	while (IR != 8'hFF) begin
// 		if(isValid(IR) && IR[1:0] == 2'b01)
// 			#5 while (!NEXT_T) begin
// 				T_state = T_state << 1;
// 				#5 if(T_state[timer])
// 					if(IR[7:5] == 0)
// 						save_state;
// 					else if(IR[7:5] == 3'b100 && NEXT_T)
// 						strobe_signals;
// 					else
// 						compare_state;
// 			end
// 		T_state = 6'h01;
// 		IR[7:5] = IR[7:5] + 1;
// 		if(IR[7:5] == 0) begin
// 			IR[4:2] = IR[4:2] + 1;
// 			if(IR[4:2] == 0)
// 				IR[1:0] = IR[1:0] + 1;
// 		end
// 		DIR = IR;
// 	end
// 	DIR = 8'h00;
// 	IR  = 8'h00;
// 	T_state = 6'h01;
// 	timer = timer + 1;
// end
//
// $stop;
//
// timer = 2;
// COUT = 1;
// while(timer < 6) begin
// 	while (IR != 8'hFF) begin
// 		if(isValid(IR) && IR[1:0] == 2'b01)
// 			#5 while (!NEXT_T) begin
// 				T_state = T_state << 1;
// 				#5 if(T_state[timer])
// 					if(IR[7:5] == 0) save_state;
// 					else             compare_state;
// 			end
// 		T_state = 6'h01;
// 		IR[7:5] = IR[7:5] + 1;
// 		if(IR[7:5] == 0) begin
// 			IR[4:2] = IR[4:2] + 1;
// 			if(IR[4:2] == 0)
// 				IR[1:0] = IR[1:0] + 1;
// 		end
// 		DIR = IR;
// 	end
// 	DIR = 8'h00;
// 	IR  = 8'h00;
// 	T_state = 6'h01;
// 	timer = timer + 1;
// end
//
// $stop;
//
// timer = 2;
// COUT = 1;
// while(timer < 6) begin
// 	while (IR != 8'hFF) begin
// 		if(isValid(IR) && IR[1:0] == 2'b10)
// 			#5 while (!NEXT_T) begin
// 				T_state = T_state << 1;
// 				#5 if(T_state[timer])
// 					if(IR[7:5] == 0) save_state;
// 					else             compare_state;
// 			end
// 		T_state = 6'h01;
// 		IR[7:5] = IR[7:5] + 1;
// 		if(IR[7:5] == 0) begin
// 			IR[4:2] = IR[4:2] + 1;
// 			if(IR[4:2] == 0)
// 				IR[1:0] = IR[1:0] + 1;
// 		end
// 		DIR = IR;
// 	end
// 	DIR = 8'h00;
// 	IR  = 8'h00;
// 	T_state = 6'h01;
// 	timer = timer + 1;
// end
//
// $stop;

// check branches

// half branches taken
// PSR = 8'hF0;
// while (IR != 8'hFF) begin
// 	if(isValid(IR) && IR[4:0] == 5'b10000) begin
// 		while (!T_state[1]) begin
// 			#5 strobe_signals;
// 			if(!NEXT_T) T_state = T_state << 1;
// 			else BCC = 1;
// 		end
// 		#5 strobe_signals;
// 	end
//
// 	BCC = 0;
// 	T_state = 6'h01;
// 	IR[7:5] = IR[7:5] + 1;
// 	if(IR[7:5] == 0) begin
// 		IR[4:2] = IR[4:2] + 1;
// 		if(IR[4:2] == 0) IR[1:0] = IR[1:0] + 1;
// 	end
// 	DIR = IR;
// end
//
// DIR = 8'h00;
// IR  = 8'h00;
// T_state = 6'h01;
//
// $stop;
//
// // branch with cross
// COUT = 1;
// iDB7 = 0;
// PSR = 8'hF0;
// while (IR != 8'hFF) begin
// 	if(isValid(IR) && IR[4:0] == 5'b10000) begin
// 		while (!T_state[1]) begin
// 			#5 strobe_signals;
// 			if(!NEXT_T) T_state = T_state << 1;
// 			else if(!BCC) BCC = 1;
// 			else begin BX = 1; BCC = 0; end
// 		end
// 		#5 strobe_signals;
// 	end
//
// 	BCC = 0;
// 	BX = 0;
// 	T_state = 6'h01;
// 	IR[7:5] = IR[7:5] + 1;
// 	if(IR[7:5] == 0) begin
// 		IR[4:2] = IR[4:2] + 1;
// 		if(IR[4:2] == 0) IR[1:0] = IR[1:0] + 1;
// 	end
// 	DIR = IR;
// end

// JUMPS with cross
// while (IR != 8'hFF) begin
// 	if(isValid(IR) && IR[4:0] == 5'b00000) begin
// 		#5 while (!NEXT_T) begin
// 			#5 strobe_signals;
// 			if(!NEXT_T) T_state = T_state << 1;
// 			#5;
// 		end
// 		#5 strobe_signals;
// 	end
// 	T_state = 6'h01;
// 	IR[7:5] = IR[7:5] + 1;
// 	if(IR[7:5] == 0) begin
// 		IR[4:2] = IR[4:2] + 1;
// 		if(IR[4:2] == 0) IR[1:0] = IR[1:0] + 1;
// 	end
// 	DIR = IR;
// end


// while (IR != 8'hFF) begin
// 	if(isValid(IR) && IR[3:0] == 5'b1100) begin
// 		#5 while (!NEXT_T) begin
// 			strobe_signals;
// 			if(!NEXT_T) T_state = T_state << 1;
// 			#5;
// 		end
// 		#5 strobe_signals;
// 	end
// 	T_state = 6'h01;
// 	IR[7:5] = IR[7:5] + 1;
// 	if(IR[7:5] == 0) begin
// 		IR[4:2] = IR[4:2] + 1;
// 		if(IR[4:2] == 0) IR[1:0] = IR[1:0] + 1;
// 	end
// 	DIR = IR;
// end

T_state = 6'h00;

while (IR != 8'hFF) begin
	if(isValid(IR) && IR[3:0] == 5'b0110 && IR[7:6] != 2'b10) begin
		#5 while (!T_state[0]) begin
			strobe_signals;
			if(NEXT_T) T_state = 1;
			SD2 = 1;
			#5;
		end
	end
	SD2 = 0;
	T_state = 6'h00;
	IR[7:5] = IR[7:5] + 1;
	if(IR[7:5] == 0) begin
		IR[4:2] = IR[4:2] + 1;
		if(IR[4:2] == 0) IR[1:0] = IR[1:0] + 1;
	end
	DIR = IR;
end

$finish;
end


endmodule // Decoder_6502_test
