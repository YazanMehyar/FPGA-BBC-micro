module Control_6502 (
	input clk,
	input [7:0] DIR,

	input [7:0] iDB,
	input ALU_COUT,
	input ALU_VOUT,
	input ALU_ZOUT,
	input ALU_NOUT,

	input RESET_pin,
	input NMI_pin,
	input IRQ_pin,
	input READY_pin,
	input SO_pin,

	output SYNC_pin,
	output PHI_1,
	output PHI_2,
	output [2:0] iDB_SEL,
	output [2:0] SB_SEL,
	output [3:0] ADBL_SEL,
	output [3:0] ADBH_SEL,
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
	output BUFF_en,
	output PC_inc,
	output [7:0] PSR_out,
	output decimal_mode);

	reg BX, BCC;
	reg SD1, SD2;
	reg COUT, VOUT, NOUT, ZOUT;
	reg READY, RESET_req;
	reg iDB7;

	wire NMI_req, IRQ_req, SO_req;
	wire NMI_T0, IRQ_T0;
	wire NEXT_T, CLEAR_T;
	wire N_en, Z_en, C_en, V_en;
	wire FLAGS;
	wire PLP, RTI, BIT, BRK;

	reg [7:0] PSR, IR;
	reg [5:0] T_state;

/**************************************************************************************************/

	assign PC_inc = T_state[0]&NMI_T0&IRQ_T0 | T_state[1]&NMI_req&IRQ_req | ~|T_state[1:0];
	assign SYNC_pin = T_state[0] & ~NEXT_T;
	assign BUFF_en = READY;
	assign PSR_out = {PSR[7:6],1'b1,IRQ_req&NMI_req,PSR[3:0]};

	// PHI_1 & PHI_2 cannot be high simultaneously
	assign PHI_1 = clk? ~PHI_2 : 0;
	assign PHI_2 = clk? 0 : ~PHI_1;

/**************************************************************************************************/

Interrupt_6502 i(
	.clk(clk),
	.NMI_pin(NMI_pin),
	.IRQ_pin(IRQ_pin),
	.SO_pin(SO_pin),
	.RESET_pin(RESET_pin&RESET_req),
	.T0(T_state[0]),
	.NEXT_T(NEXT_T),
	.I_mask(PSR[2]),

	.NMI_req(NMI_req),
	.NMI_T0(NMI_T0),
	.IRQ_req(IRQ_req),
	.IRQ_T0(IRQ_T0),
	.SO_req(SO_req));


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
	.NMI_req(NMI_req),
	.RESET_req(RESET_req),
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
	.DIR_en(DIR_en),
	.decimal_en(decimal_mode));

/**************************************************************************************************/
always @ (posedge clk) begin
	READY <= READY_pin | ~RnW;
	RESET_req <= RESET_req? RESET_pin : T_state[0] & RESET_pin;
end

always @ (posedge clk) begin
	if(~RESET_pin) 	 T_state <= 6'b000_010;
	else if(READY) begin
		if(CLEAR_T) T_state <= 6'b000_000;
		else if(NEXT_T) T_state <= 6'b000_001;
		else T_state <= T_state << 1;
	end
end

always @ (posedge clk) begin
	if(~RESET_pin)
		IR <= 8'h00;
	else if(T_state[1] & READY)
		IR <= IRQ_req&NMI_req&RESET_req? DIR[7:0] : 8'h00;
end

always @ (posedge clk) begin
	if (~RESET_pin) PSR <= 8'h00;
	else if (READY) begin
		if(T_state[0] & FLAGS)
			case (IR[7:6])
			2'b00: PSR[0] <= IR[5];
			2'b01: PSR[2] <= IR[5];
			2'b10: PSR[6] <= SO_req;
			2'b11: PSR[3] <= IR[5];
			endcase
		else if(T_state[0] & PLP) PSR <= {iDB[7],SO_req|iDB[6],iDB[5:0]};
		else if(T_state[0] & BIT) PSR[7:6] <= {iDB[7],SO_req|iDB[6]};
		else if(T_state[4] & RTI) PSR <= iDB;
		else if(T_state[4] & BRK) PSR[2] <= 1'b1;
		else if(T_state[1] | SD2) begin
			PSR[7] <= N_en? NOUT : PSR[7];
			PSR[6] <= V_en? VOUT : PSR[6];
			PSR[1] <= Z_en? ZOUT : PSR[1];
			PSR[0] <= C_en? COUT : PSR[0];
		end else PSR[6] <= PSR[6]|SO_req;
	end else PSR[6] <= PSR[6]|SO_req;
end

always @ (posedge clk) begin
	if(~RESET_pin) begin
		SD1  <= 1'b0;
		SD2  <= 1'b0;
		BCC  <= 1'b0;
	end else if(READY) begin
		VOUT <= ALU_VOUT; COUT <= ALU_COUT; ZOUT <= ALU_ZOUT; NOUT <= ALU_NOUT;
		SD1  <= CLEAR_T;  SD2  <= SD1;
		BCC  <= T_state[0] & NEXT_T & ~BCC;
		BX   <= T_state[0] & NEXT_T & BCC;
		iDB7 <= iDB[7];
	end
end

endmodule // Control_6502
