`include "TOP.vh"

module Timing_Generator(
	input CLK,
	input CLK_16en,
	
	output CLK_8en,
	output CLK_4en,
	output CLK_2en,
	output CLK_1en,
	output CLK_2ven);

	`ifdef SIMULATION
		initial begin
			COUNTER = 0;
		end
	`endif
	
	reg [3:0] COUNTER;
	always @ (posedge CLK) if(CLK_16en) COUNTER <= COUNTER + 1;
	
	assign CLK_8en = ~COUNTER[0]   &CLK_16en;
	assign CLK_4en = ~|COUNTER[1:0]&CLK_16en;
	assign CLK_2en = ~|COUNTER[2:0]&CLK_16en;
	assign CLK_1en = ~|COUNTER[3:0]&CLK_16en;
	
	// CRTC clock, it interleaves with the processor clock (CLK_2en)
	assign CLK_2ven = CLK_4en&~CLK_2en;

endmodule
