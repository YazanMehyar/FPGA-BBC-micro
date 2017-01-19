
`include "Decode_6502.vh"
`define NMI_LOW_VEC 8'hFA
`define RES_LOW_VEC 8'hFC
`define IRQ_LOW_VEC 8'hFE

module Address_bus (
	input clk,
	input [3:0] ADBL_SEL,
	input [7:0] PCL,
	input [7:0] AOR,
	input [7:0] DIR,
	input [7:0] SP,

	input [3:0] ADBH_SEL,
	input [7:0] PCH,

	input BUFF_en,

	output reg [7:0] ADB_lo,
	output [7:0] ADB_lo_pin,
	output reg [7:0] ADB_hi,
	output [7:0] ADB_hi_pin);

reg [7:0] buff_lo, buff_hi;

always @ (posedge clk) begin
	if(BUFF_en) begin
		buff_hi <= ADB_hi;
		buff_lo <= ADB_lo;
	end
end

// ADB_lo
always @ ( * ) begin
	case (ADBL_SEL[2:0])
		`ADBL_PCL:   ADB_lo = PCL;
		`ADBL_AOR:   ADB_lo = AOR;
		`ADBL_STACK: ADB_lo = SP;
		`ADBL_DIR:   ADB_lo = DIR;
		`ADBL_IRQ:   ADB_lo = `IRQ_LOW_VEC;
		`ADBL_NMI:   ADB_lo = `NMI_LOW_VEC;
		`ADBL_RESET: ADB_lo = `RES_LOW_VEC;
		`ADBL_BUFFER:ADB_lo = buff_lo;
		default: ADB_lo = 8'hxx;
	endcase
end

assign ADB_lo_pin = ADBL_SEL[3]? buff_lo : ADB_lo;

// ADB_hi
always @ ( * ) begin
	case (ADBH_SEL[2:0])
		`ADBH_PCH:   ADB_hi = PCH;
		`ADBH_AOR:   ADB_hi = AOR;
		`ADBH_DIR:   ADB_hi = DIR;
		`ADBH_ZPG:   ADB_hi = 8'h00;
		`ADBH_STACK: ADB_hi = 8'h01;
		`ADBH_VECTOR:ADB_hi = 8'hFF;
		`ADBH_BUFFER:ADB_hi = buff_hi;
		default: ADB_hi = 8'hxx;
	endcase
end

assign ADB_hi_pin = ADBH_SEL[3]? buff_hi : ADB_hi;

endmodule //
