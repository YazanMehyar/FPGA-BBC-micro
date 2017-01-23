module ALU_6502 (
	input [3:0] ALU_FUNC,
	input D_flag,
	input CARRY_IN,

	input [7:0] SB,
	input [7:0] ALU_B,

	output reg ALU_COUT,
	output reg ALU_VOUT,
	output reg ALU_NOUT,
	output reg ALU_ZOUT,

	output reg [7:0] ALU_out
	);

reg half_dec_c;
reg dec_c;
reg half_hex_c;

wire [7:0] rALU_B = ALU_FUNC == `ALU_SUB? ~ALU_B : ALU_B;

always @ ( * ) begin
	ALU_COUT = 0;
	half_dec_c = 0;
	dec_c = 0;
	half_hex_c = 1'bx;

	case (ALU_FUNC)
		`ALU_ADD,
		`ALU_SUB:	begin
					{half_hex_c,ALU_out[3:0]} = {1'b0,SB[3:0]} + {1'b0,rALU_B[3:0]} + CARRY_IN;
					half_dec_c = half_hex_c;
					{ALU_COUT,ALU_out[7:4]} = {1'b0,SB[7:4]} + {1'b0,rALU_B[7:4]} + half_hex_c;
					end
		`ALU_AND:	ALU_out = SB & ALU_B;
		`ALU_ORA:	ALU_out = SB | ALU_B;
		`ALU_EOR:	ALU_out = SB ^ ALU_B;
		`ALU_INC:	{ALU_COUT,ALU_out} = {1'b0,ALU_B} + 1;
		`ALU_DEC:	{ALU_COUT,ALU_out} = {1'b0,ALU_B} + 8'hFF;
		`ALU_PASS:	ALU_out = ALU_B;
		`ALU_LSR:	{ALU_out,ALU_COUT} = {1'b0,ALU_B};
		`ALU_ASL:	{ALU_COUT,ALU_out} = {ALU_B,1'b0};
		`ALU_ROR:	{ALU_out,ALU_COUT} = {CARRY_IN,ALU_B};
		`ALU_ROL:	{ALU_COUT,ALU_out} = {ALU_B,CARRY_IN};
		default: ALU_out = 8'hxx;
	endcase

	ALU_ZOUT = ~|ALU_out;
	ALU_NOUT = ALU_out[7];
	ALU_VOUT = (SB[7]~^rALU_B[7])&(ALU_out[7]^SB[7]);

	// intentionally corrupt V, N, Z flags on Decimal model

	if(~ALU_FUNC[0] & D_flag) begin // ADD

		if(half_dec_c|ALU_out[3]&(|ALU_out[2:1]))
			{dec_c,ALU_out} = {1'b0,ALU_out} + 9'd6;
		
		ALU_NOUT = ALU_out[7]; // weird confirmed behaviour
		ALU_COUT = dec_c | ALU_out[7] & (|ALU_out[6:5]) | ALU_COUT;
		if(ALU_COUT) ALU_out[7:4] = ALU_out[7:4] + 5'd6;


	end else if(D_flag) begin // SUB

		if(~half_dec_c) ALU_out[3:0] = ALU_out[3:0] + 4'd10;
		if(~ALU_COUT)   ALU_out[7:4] = ALU_out[7:4] + 4'd10;

	end

end

endmodule // ALU_6502
