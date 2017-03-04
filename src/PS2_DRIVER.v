`include "TOP.vh"

module PS2_DRIVER(
	input clk,
	input clk_en,
	input nRESET,
	input PS2_CLK,
	input PS2_DATA,

	output [7:0] DATA,
	output DONE);

/****************************************************************************************/

	reg [3:0] clk_filter;
	always @ (posedge clk)
		if(~nRESET)		clk_filter <= 4'hF;
		else if(clk_en) begin
			clk_filter  <= {clk_filter[2:0],PS2_CLK};
		end

/****************************************************************************************/
	wire NEGEDGE_PS2CLK = ~|clk_filter;
	wire POSEDGE_PS2CLK =  &clk_filter;

    reg CAPTURE;
	reg RELEASE;
	reg [10:0] MESSAGE;

	always @ (posedge clk) begin
		if(~nRESET) begin
			MESSAGE  <= 11'h7FF;
			CAPTURE  <=  0;
			RELEASE  <=  0;
		end else if(clk_en) begin
			if(DONE)
				MESSAGE <= 11'h7FF;
			else if(CAPTURE)
				MESSAGE <= {PS2_DATA,MESSAGE[10:1]};

			if(CAPTURE)
				CAPTURE <= 0;
			else if(NEGEDGE_PS2CLK&RELEASE) begin
				CAPTURE <= 1;
				RELEASE <= 0;
			end else if(POSEDGE_PS2CLK)
				RELEASE <= 1;

		end
	end

	assign DATA = MESSAGE[8:1];
	assign DONE = ~MESSAGE[0]&MESSAGE[10];

endmodule
