module PS2_DRIVER(
	input CLK,
	input nRESET,
	input PS2_CLK,
	input PS2_DATA,
	input En,

	output reg [7:0] DATA,
	output reg DONE);

/****************************************************************************************/

	wire NEGEDGE_PS2_CLK;
	Edge_Trigger e(
		.clk(CLK),
		.EDGE_pin(PS2_CLK),
		.nRESET_pin(nRESET),
		.En(En),
		.nEDGE(NEGEDGE_PS2_CLK)
		);

	reg rPS2_DATA;
	always @ (negedge PS2_CLK) begin
		rPS2_DATA <= PS2_DATA;
	end

/****************************************************************************************/

	reg READ_STATE;
	reg [3:0] BIT_COUNT;
	reg [10:0] MESSAGE;

	always @(posedge CLK) begin
		if(~nRESET)
			READ_STATE <= 0;
		else if (En)
			if(READ_STATE) READ_STATE <= |BIT_COUNT;
			else if(~NEGEDGE_PS2_CLK) READ_STATE <= ~rPS2_DATA;
	end

	always @ (posedge CLK) begin
		if(~nRESET)
			BIT_COUNT <= 10;
		else if(En) begin
			if(~|BIT_COUNT)
				BIT_COUNT <= 10;
			else if(READ_STATE | ~NEGEDGE_PS2_CLK & ~rPS2_DATA)
				BIT_COUNT <= BIT_COUNT + 4'hF;
		end
	end

	always @ (posedge CLK) begin
		if(En & READ_STATE | En & ~NEGEDGE_PS2_CLK)
			MESSAGE <= {rPS2_DATA,MESSAGE[10:1]};
	end

/****************************************************************************************/

	reg CAPTURE;
	always @ (posedge CLK) begin
		if(En) CAPTURE <= ~|BIT_COUNT & ~MESSAGE[1] & ^MESSAGE[10:2];
	end

	always @ (posedge CLK) begin
		if(En) DATA <= MESSAGE[8:1];
	end

	always @ (posedge CLK) begin
		if(~nRESET) DONE <= 0;
		else if(En) DONE <= DONE? 0 : CAPTURE & MESSAGE[10];
	end

endmodule
