`include "MOS6502.vh"

module MOS6502_Control (
	input clk,
	input clk_en,
	input [7:0] DIR,

	input [7:0] iDB,
	input ALU_COUT,
	input ALU_VOUT,
	input ALU_ZOUT,
	input ALU_NOUT,

	input nRESET,
	input nNMI,
	input nIRQ,
	input READY_pin,
	input nSO,

	output SYNC_pin,
	output [2:0] iDB_SEL,
	output [2:0] SB_SEL,
	output [2:0] ADBL_SEL,
	output [2:0] ADBH_SEL,
	output [3:0] ALU_FUNC,
	output ALU_B_SEL,
	output CARRY_IN,
	output RnW,
	output ACC_en,
	output iX_en,
	output iY_en,
	output SP_en,
	output PC_en,
	output AOR_en,
	output DIR_en,
	output PC_inc,
	output [7:0] PSR_out,
	output [7:0] IR_out,
	output decimal_mode
	);

	reg BX, BCC;
	reg SD1, SD2;
	reg COUT, VOUT, NOUT, ZOUT;
	reg READY, nRESET_req;
	reg iDB7;

	wire nNMI_req, nIRQ_req, SO_req;
	wire NEXT_T, NEXT_S;
	wire N_en, Z_en, C_en, V_en;
	wire FLAGS;
	wire PLP, PLA, RTI, BIT, BRK;

	reg [7:0] PSR, IR;
	reg [3:0] T_state;

/**************************************************************************************************/

	assign PC_inc = nNMI_req&nIRQ_req || (T_state != `T0 && T_state != `T1);
	assign SYNC_pin = ~|T_state[3:2] & ~NEXT_T;
	assign PSR_out = {PSR[7:6],1'b1,nIRQ_req&nNMI_req,PSR[3:0]};
	assign IR_out = IR;

/**************************************************************************************************/

MOS6502_Interrupt interrupt(
	.clk(clk),
	.nRESET(nRESET&nRESET_req),
	.clk_en(clk_en),
	.nNMI(nNMI),
	.nIRQ(nIRQ),
	.nSO(nSO),
	.NEXT_T(NEXT_T),
	.I_mask(PSR[2]),

	.nNMI_req(nNMI_req),
	.nIRQ_req(nIRQ_req),
	.SO_req(SO_req));


MOS6502_Decode decoder(
	.IR(IR),
	.T_state(T_state),
	.PSR(PSR),
	.DIR(DIR),
	.iDB7(iDB7),
	.COUT(COUT),
	.nIRQ_req(nIRQ_req),
	.nNMI_req(nNMI_req),
	.nRESET_req(nRESET_req),
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
	.NEXT_S(NEXT_S),
	.N_en(N_en),
	.Z_en(Z_en),
	.C_en(C_en),
	.V_en(V_en),
	.FLAGS(FLAGS),
	.PLP(PLP),
	.PLA(PLA),
	.RTI(RTI),
	.BIT(BIT),
	.BRK(BRK),
	.ACC_en(ACC_en),
	.iX_en(iX_en),
	.iY_en(iY_en),
	.SP_en(SP_en),
	.PC_en(PC_en),
	.AOR_en(AOR_en),
	.DIR_en(DIR_en),
	.decimal_en(decimal_mode));

/**************************************************************************************************/
always @ (posedge clk) begin
	READY <= READY_pin | ~RnW;

	if(~nRESET) 	nRESET_req	<= 1'b0;
	else if(clk_en) nRESET_req	<= (nRESET_req || T_state == `T0);
end

always @ (posedge clk) begin
	if(~nRESET) 	 T_state <= `T1;
	else if(clk_en)
		if(READY) begin
			if(NEXT_S)
				T_state <= `TSD1;
			else if(NEXT_T) case (T_state)
				`T0:    T_state <= `T0BCC;
				`T0BCC: T_state <= `T0BX;
				default:T_state <= `T0;
			endcase else case(T_state)
			`T0BCC:	T_state <= `T1;
			`T0BX:	T_state <= `T1;
			`T0:	T_state <= `T1;
			`T1:	T_state <= `T2;
			`T2:	T_state <= `T3;
			`T3:	T_state <= `T4;
			`T4:	T_state <= `T5;
			`T5:	T_state <= `TVEC;
			`TSD1:	T_state <= `TSD2;
			default:T_state <=  4'hx;
			endcase
		end
end

always @ (posedge clk) begin
	if(~nRESET)	IR <= 8'h00;
	else if(clk_en && READY && T_state == `T1)
		IR <= nIRQ_req&nNMI_req&nRESET_req? DIR[7:0] : 8'h00;
end

always @ (posedge clk)
	if (~nRESET)
		PSR <= 8'h00;
	else if(clk_en)
		if (READY) case (T_state)
			`T0:	case(1'b1)
					PLP: PSR <= iDB[7:0];
					PLA: begin PSR[7] <= iDB[7]; PSR[1] = ~|iDB; end
					BIT: PSR[7:6] <= iDB[7:6];
					FLAGS: case (IR[7:6])
						2'b00: PSR[0] <= IR[5];
						2'b01: PSR[2] <= IR[5];
						2'b10: PSR[6] <= 1'b0;
						2'b11: PSR[3] <= IR[5];
						endcase
					endcase
			`T1,`TSD2: begin
					PSR[7] <= N_en? NOUT : PSR[7];
					PSR[6] <= V_en? VOUT : PSR[6] | (SO_req && T_state == `T1);
					PSR[1] <= Z_en? ZOUT : PSR[1];
					PSR[0] <= C_en? COUT : PSR[0];
					end
			`T4:	case (1'b1)
					RTI: PSR <= iDB;
					BRK: PSR[2] <= 1'b1;
					endcase
			endcase else PSR[6] <= PSR[6]|SO_req;

always @ (posedge clk)
	if(clk_en&READY) begin
		VOUT <= ALU_VOUT;
		COUT <= ALU_COUT;
		ZOUT <= ALU_ZOUT;
		NOUT <= ALU_NOUT;
		iDB7 <= iDB[7];
	end

endmodule
