module VideoULA (
	input clk16MHz,
	input nRESET,
	input A0,
	input nCS,
	input DISEN,
	input CURSOR,
	input [7:0] DATA,
	input [7:0] pDATA,

	output reg clk8MHz,
	output reg clk4MHz,
	output reg clk2MHz,
	output reg clk1MHz,
	output clkCRTC,
	output REDout,
	output GREENout,
	output BLUEout);

	/**
		NOTE: Parts not implemented:
		 - INV pin and function,
		 - Red, Green & Blue input pins from the teletext chip
		 - I added a nRESET pin
	*/

/****************************************************************************************/

	reg [7:0] CONTROL = 0;
	reg [7:0] SHIFT_reg = 0;
	reg [3:0] PALETTE_mem [0:15];

/****************************************************************************************/
	initial begin
		clk1MHz = 0;
		clk2MHz = 0;
		clk4MHz = 0;
		clk8MHz = 0;
	end

	always @ (posedge clk16MHz) clk8MHz <= #1 ~clk8MHz;
	always @ (posedge clk8MHz)  clk4MHz <= #1 ~clk4MHz;
	always @ (posedge clk4MHz)  clk2MHz <= #1 ~clk2MHz;
	always @ (posedge clk2MHz)  clk1MHz <= #1 ~clk1MHz;

	assign clkCRTC = CONTROL[4]? clk2MHz : clk1MHz;

/****************************************************************************************/

	wire CRTC_posedge = CONTROL[4]? clk8MHz&clk4MHz&~clk2MHz :
									clk8MHz&clk4MHz&~clk2MHz&clk1MHz ;

	reg SHIFT_en; // wire
	always @ ( * ) begin
		case (CONTROL[3:2])
			2'b00: SHIFT_en = clk8MHz&clk4MHz&~clk2MHz;
			2'b01: SHIFT_en = clk8MHz&clk4MHz;
			2'b10: SHIFT_en = clk8MHz;
			2'b11: SHIFT_en = 1;
			default: SHIFT_en = 1'bx;
		endcase
	end

	always @ (posedge clk16MHz) begin
		if(CRTC_posedge)	SHIFT_reg <= DATA;
		else if(SHIFT_en)	SHIFT_reg <= {SHIFT_reg[6:0],1'b1};
	end

/****************************************************************************************/

	wire [3:0] PALETTE_out = PALETTE_mem[{SHIFT_reg[7],SHIFT_reg[5],SHIFT_reg[3],SHIFT_reg[1]}];
	always @ (posedge clk2MHz) begin
		if(~nCS)
		 	if(A0)  PALETTE_mem[pDATA[7:4]] <= pDATA[3:0];
			else	CONTROL <= pDATA;
	end

/****************************************************************************************/

	wire FLASH = ~(PALETTE_out[3]&CONTROL[0]);
	assign {BLUEout,GREENout,REDout} = DISEN? FLASH? ~PALETTE_out[2:0] : PALETTE_out[2:0]
											: 3'b000;

endmodule // VideoULA
