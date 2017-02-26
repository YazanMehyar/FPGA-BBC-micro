module PS2_DRIVER(
	input CLK,
	input nRESET,
	input PS2_CLK,
	input PS2_DATA,
	input En,

	output [7:0] DATA,
	output reg DONE);

/****************************************************************************************/

	reg En;
	wire NEGEDGE_PS2_CLK;
	Edge_Trigger e(
		.clk(CLK),
		.EDGE_pin(PS2_CLK),
		.nRESET_pin(nRESET),
		.En(En),
		.nEDGE(NEGEDGE_PS2_CLK)
		);

/****************************************************************************************/

	reg READ_STATE;
	reg [3:0] BIT_COUNT;
	reg [10:0] MESSAGE;

	always @(posedge CLK) begin
		if(~nRESET)
			READ_STATE <= 0;
		else if (En)
			if(READ_STATE) READ_STATE <= |BIT_COUNT;
			else if(~NEGEDGE_PS2_CLK) READ_STATE <= 1;
	end

	always @ (posedge CLK) begin
		if(~nRESET)
			BIT_COUNT <= 11;
		else if(READ_STATE & En)
			BIT_COUNT <= BIT_COUNT + 4'hF;
		else
			BIT_COUNT <= 11;
	end

	always @ (posedge CLK) begin
		if(En & READ_STATE)
			MESSAGE <= {PS2_DATA,MESSAGE[10:1]};
	end

/****************************************************************************************/

	assign DATA = MESSAGE[8:1];

	always @ (posedge CLK) begin
		if(~nRESET) DONE <= 0;
		else if(En) DONE <= ~|BIT_COUNT & MESSAGE[10] & ~MESSAGE[0] & ^MESSAGE[9:1];
	end

endmodule
