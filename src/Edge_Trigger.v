module Edge_Trigger (
	input clk,
	input EDGE_pin,
	input RESET_pin,
	input T0,
	input NEXT_T,

	output reg EDGE);

	reg EDGE_R0, EDGE_R1;

	wire EDGE_negedge = EDGE_R0 | ~EDGE_R1;

	always @ (posedge clk)
		if(~RESET_pin) begin // active low
			EDGE_R0 <= 1'b1;
			EDGE_R1 <= 1'b1;
			EDGE <= 1'b1;
		end else begin
			EDGE_R0 <= EDGE_pin;
			EDGE_R1 <= EDGE_R0;
			if(T0 & ~NEXT_T | EDGE)	EDGE <= EDGE_negedge;
		end
endmodule // Edge_Trigger
