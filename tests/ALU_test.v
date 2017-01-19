`include "Decode_6502.vh"

module ALU_test ();
	reg [7:0] SB;
	reg [7:0] ALU_B;
	reg D_flag;
	reg CARRY_IN;
	reg [3:0] ALU_FUNC;

	wire [7:0] ALU_out;
	wire ALU_COUT;
	wire ALU_VOUT;
	wire ALU_NOUT;
	wire ALU_ZOUT;

	ALU_6502 a(
	.SB(SB),
	.ALU_B(ALU_B),
	.D_flag(D_flag),
	.CARRY_IN(CARRY_IN),
	.ALU_FUNC(ALU_FUNC),
	.ALU_out(ALU_out),
	.ALU_COUT(ALU_COUT),
	.ALU_VOUT(ALU_VOUT),
	.ALU_NOUT(ALU_NOUT),
	.ALU_ZOUT(ALU_ZOUT)
	);

initial begin
	// test Decimal mode

	// #1
	// CLD      ; Binary mode (binary addition: 88 + 70 + 1 = 159)
	// SEC      ; Note: carry is set, not clear!
	// LDA #$58 ; 88
	// ADC #$46 ; 70 (after this instruction, C = 0, A = $9F = 159)
	D_flag = 0; CARRY_IN = 1; SB = 8'h58; ALU_B = 8'h46;
	ALU_FUNC = `ALU_ADD;
	#5 display_arithm;

	// #2
	// SED      ; Decimal mode (BCD addition: 58 + 46 + 1 = 105)
	// SEC      ; Note: carry is set, not clear!
	// LDA #$58
	// ADC #$46 ; After this instruction, C = 1, A = $05
	D_flag = 1; CARRY_IN = 1; SB = 8'h58; ALU_B = 8'h46;
	ALU_FUNC = `ALU_ADD;
	#5 display_arithm;

	// #3
	// SED      ; Decimal mode (BCD addition: 12 + 34 = 46)
	// CLC
	// LDA #$12
	// ADC #$34 ; After this instruction, C = 0, A = $46
	D_flag = 1; CARRY_IN = 0; SB = 8'h12; ALU_B = 8'h34;
	ALU_FUNC = `ALU_ADD;
	#5 display_arithm;

	// #4
	// SED      ; Decimal mode (BCD addition: 15 + 26 = 41)
	// CLC
	// LDA #$15
	// ADC #$26 ; After this instruction, C = 0, A = $41
	D_flag = 1; CARRY_IN = 0; SB = 8'h15; ALU_B = 8'h26;
	ALU_FUNC = `ALU_ADD;
	#5 display_arithm;

	// #5
	// SED      ; Decimal mode (BCD addition: 81 + 92 = 173)
	// CLC
	// LDA #$81
	// ADC #$92 ; After this instruction, C = 1, A = $73
	D_flag = 1; CARRY_IN = 0; SB = 8'h81; ALU_B = 8'h92;
	ALU_FUNC = `ALU_ADD;
	#5 display_arithm;
	$stop;

	// #6
	// SED      ; Decimal mode (BCD subtraction: 46 - 12 = 34)
	// SEC
	// LDA #$46
	// SBC #$12 ; After this instruction, C = 1, A = $34)
	D_flag = 1; CARRY_IN = 1; SB = 8'h46; ALU_B = 8'h12;
	ALU_FUNC = `ALU_SUB;
	#5 display_arithm;

	// #7
	// SED      ; Decimal mode (BCD subtraction: 40 - 13 = 27)
	// SEC
	// LDA #$40
	// SBC #$13 ; After this instruction, C = 1, A = $27)
	D_flag = 1; CARRY_IN = 1; SB = 8'h40; ALU_B = 8'h13;
	ALU_FUNC = `ALU_SUB;
	#5 display_arithm;

	// #8
	// SED      ; Decimal mode (BCD subtraction: 32 - 2 - 1 = 29)
	// CLC      ; Note: carry is clear, not set!
	// LDA #$32
	// SBC #$02 ; After this instruction, C = 1, A = $29)
	D_flag = 1; CARRY_IN = 0; SB = 8'h32; ALU_B = 8'h02;
	ALU_FUNC = `ALU_SUB;
	#5 display_arithm;

	// #9
	// SED      ; Decimal mode (BCD subtraction: 12 - 21)
	// SEC
	// LDA #$12
	// SBC #$21 ; After this instruction, C = 0, A = $91)
	D_flag = 1; CARRY_IN = 1; SB = 8'h12; ALU_B = 8'h21;
	ALU_FUNC = `ALU_SUB;
	#5 display_arithm;

	// #10
	// SED      ; Decimal mode (BCD subtraction: 21 - 34)
	// SEC
	// LDA #$21
	// SBC #$34 ; After this instruction, C = 0, A = $87)
	D_flag = 1; CARRY_IN = 1; SB = 8'h21; ALU_B = 8'h34;
	ALU_FUNC = `ALU_SUB;
	#5 display_arithm;
	$finish;
end

task display_arithm;
begin
if(ALU_FUNC == `ALU_ADD)
	$display("%h + %h + %b = %h __ Cout is %b", SB, ALU_B, CARRY_IN, ALU_out, ALU_COUT);
else
	$display("%h - %h - %b = %h __ Cout is %b", SB, ALU_B, ~CARRY_IN, ALU_out, ALU_COUT);
end
endtask

endmodule // ALU_test
