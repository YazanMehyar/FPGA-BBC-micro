module VideoULA (
	input clk16MHz,
	input nRESET,
	input A0,
	input nCS,
	input DISEN,
	input CURSOR,
	input [7:0] DATA,

	output clk8MHz,
	output clk4MHz,
	output clk2MHz,
	output clk1MHz,
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

	reg [7:0] CONTROL;
	reg [7:0] SHIFT_reg;
	reg [3:0] PALETTE_mem [0:15];

/****************************************************************************************/

	reg [3:0] clk_COUNTER = 0;

	assign clk8MHz = clk_COUNTER[0];
	assign clk4MHz = clk_COUNTER[1];
	assign clk2MHz = clk_COUNTER[2];
	assign clk1MHz = clk_COUNTER[3];
	assign clkCRTC = CONTROL[4]? clk2MHz : clk1MHz;

	always @ (posedge clk16MHz) begin
		clk_COUNTER <= clk_COUNTER + 1;
	end

/****************************************************************************************/

	wire CRTC_posedge = CONTROL[4]? ~clk_COUNTER[2] & &clk_COUNTER[1:0] :
									~clk_COUNTER[3] & &clk_COUNTER[2:0] ;

	reg SHIFT_en; // wire
	always @ ( * ) begin
		case (CONTROL[3:2])
			2'b00: SHIFT_en = &clk_COUNTER[2:0];
			2'b01: SHIFT_en = &clk_COUNTER[1:0];
			2'b10: SHIFT_en = clk_COUNTER[0];
			2'b11: SHIFT_en = 1;
			default: ;
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
		 	if(A0)  PALETTE_mem[DATA[7:4]] <= DATA[3:0];
			else	CONTROL <= DATA;
	end

/****************************************************************************************/

	wire FLASH = ~(PALETTE_out[3]&CONTROL[0]);
	assign {BLUEout,GREENout,REDout} = DISEN? FLASH? ~PALETTE_out[2:0] : PALETTE_out[2:0]
											: 3'b000;

endmodule // VideoULA
