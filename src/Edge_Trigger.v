module Edge_Trigger (
	input clk,
	input EDGE_pin,
	input nRESET_pin,
	input En,

	output reg nEDGE);

	reg EDGE_R0, EDGE_R1;

	wire EDGE_negedge = EDGE_R0 | ~EDGE_R1;

	always @ (posedge clk)
		if(~nRESET_pin) begin // active low
			EDGE_R0 <= 1'b1;
			EDGE_R1 <= 1'b1;
			nEDGE <= 1'b1;
		end else begin
			EDGE_R0 <= EDGE_pin;
			EDGE_R1 <= EDGE_R0;
			if(En | nEDGE)	nEDGE <= EDGE_negedge;
		end
endmodule // Edge_Trigger
