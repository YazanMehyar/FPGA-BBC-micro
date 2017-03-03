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
    reg START;
	reg [10:0] MESSAGE;
	reg [3:0]  BITCOUNT;

	always @ (posedge clk) begin
		if(~nRESET) begin
			MESSAGE  <= 11'h7FF;
			BITCOUNT <=  4'h0;
			CAPTURE  <=  1'b0;
			START	 <=  1'b0;
		end else if(clk_en)
            if(DONE) begin
                BITCOUNT <= 4'h0;
                START	 <= 0;
			end else if(NEGEDGE_PS2CLK & ~CAPTURE & ~DONE) begin
	            if(BITCOUNT == 0 && PS2_DATA == 0 || START) begin
					MESSAGE <= {PS2_DATA,MESSAGE[10:1]};
					CAPTURE <= 1'b1;
					BITCOUNT <= BITCOUNT + 1'b1;
					START <= 1;
	            end 
			end else if(POSEDGE_PS2CLK)
                CAPTURE <= 1'b0;
	end
	
	always @ (*) DATA = MESSAGE[8:1];
	always @ (*) DONE = (BITCOUNT == 4'hB);
	
/****************************************************************************************/
// Test Helper
`ifdef SIMULATION
/*	
	initial forever begin
		@(posedge clk)
		if(clk_en) begin
			if(NEGEDGE_PS2CLK&~DONE&~CAPTURE&START) begin
				$display("PS2_INTERFACE -- MESSAGE now is %H", MESSAGE);
				$display("Bit count is %d", BITCOUNT);
			end else if(DONE)
				$display("MESSAGE %H", MESSAGE);
		end
	end
*/
`endif

endmodule
