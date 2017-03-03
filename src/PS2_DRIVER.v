`include "TOP.vh"

module PS2_DRIVER(
	input clk,
	input clk_en,
	input nRESET,
	input PS2_CLK,
	input PS2_DATA,

	output reg [7:0] DATA,
	output reg DONE);

/****************************************************************************************/

	reg [7:0] clk_filter;
	reg prev_PS2CLK;
	always @ (posedge clk)
		if(~nRESET)		clk_filter <= 8'hFF;
		else if(clk_en) begin
			clk_filter  <= {clk_filter[6:0],PS2_CLK};
			prev_PS2CLK <= |clk_filter;
		end

/****************************************************************************************/
	wire NEGEDGE_PS2CLK = ~|clk_filter & prev_PS2CLK;

	reg [10:0] MESSAGE;
	wire wDONE = MESSAGE[10]&~MESSAGE[0]&~^MESSAGE[9:1];
	always @ (posedge clk) begin
		if(~nRESET)
			MESSAGE <= 11'h7FF;
		else if(clk_en)
			if(DONE)
				MESSAGE <= 11'h7FF;
			else if(NEGEDGE_PS2CLK)
				MESSAGE <= {PS2_DATA,MESSAGE[10:1]};

		if(~nRESET)		DONE <= 0;
		else if(clk_en)
			if(DONE)	DONE <= 0;
			else		DONE <= wDONE;

		if(clk_en&wDONE)
			DATA <= MESSAGE[8:1];
	end

endmodule
