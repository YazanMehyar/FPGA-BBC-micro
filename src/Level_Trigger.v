module Level_Trigger (
	input clk,
	input LEVEL_pin,
	input RESET_pin,
	input T0,

	output reg LEVEL);

	always @ (posedge clk)
		if(~RESET_pin) // active low reset
			LEVEL <= 1'b1;
		else if(~T0)
			LEVEL <= LEVEL_pin;

endmodule // Level_Trigger
