module Level_Trigger (
	input clk,
	input LEVEL_pin,
	input RESET_pin,
	input nEn,

	output reg LEVEL);

	always @ (posedge clk)
		if(~RESET_pin) // active low reset
			LEVEL <= 1'b1;
		else if(~nEn)
			LEVEL <= LEVEL_pin;

endmodule // Level_Trigger
