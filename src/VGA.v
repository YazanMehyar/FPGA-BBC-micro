`include "VGA.vh"

module VGA (
	input nRESET,
	input PIXELCLK,
	output VGA_HS,
	output VGA_VS,
	output ENDofLINE,
	output NEWSCREEN,
	output DISEN
	);

	assign ENDofLINE = ~|H_COUNTER;
	assign NEWSCREEN = ~|V_COUNTER & ENDofLINE;
	assign DISEN	 = H_DISPLAY&V_DISPLAY;
	assign VGA_HS    = H_PULSE;
	assign VGA_VS    = V_PULSE;

	// H_SYNC @ 31.46 KHz
	reg H_BACK;
	reg H_DISPLAY;
	reg H_PULSE;
	reg [9:0] H_COUNTER;
	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) begin
			H_COUNTER <= `H_COUNT_INIT;
			H_BACK    <= 0;
			H_DISPLAY <= 0;
			H_PULSE <= 0;
		end else begin
			if(|H_COUNTER)
				H_COUNTER <= H_COUNTER - 1;
			else
				H_COUNTER <= `H_COUNT_INIT;
			
			if(H_DISPLAY) begin
				H_BACK		<= 0;
				H_DISPLAY	<= |H_COUNTER;
				H_PULSE	<= 0;
			end else if(H_BACK) begin
				H_BACK		<= H_COUNTER != `H_DISPLAY;
				H_DISPLAY	<= H_COUNTER == `H_DISPLAY;
				H_PULSE	<= 0;
			end else if(H_PULSE) begin
				H_BACK		<= H_COUNTER == `H_BACK;
				H_DISPLAY	<= 0;
				H_PULSE	<= H_COUNTER != `H_BACK;
			end else begin
				H_BACK		<= 0;
				H_DISPLAY	<= 0;
				H_PULSE	<= H_COUNTER == `H_PULSE;
			end
		end
	end

	// V_SYNC @ 60Hz
	reg V_BACK;
	reg V_DISPLAY;
	reg V_PULSE;
	reg [9:0] V_COUNTER;
	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) begin
			V_COUNTER <= `V_COUNT_INIT;
			V_BACK    <= 0;
			V_DISPLAY <= 0;
			V_PULSE <= 0;
		end else if(ENDofLINE) begin
			if(|V_COUNTER)
				V_COUNTER <= V_COUNTER - 1;
			else
				V_COUNTER <= `V_COUNT_INIT;
			
			if(V_DISPLAY) begin
				V_BACK		<= 0;
				V_DISPLAY	<= |V_COUNTER;
				V_PULSE	<= 0;
			end else if(V_BACK) begin
				V_BACK		<= V_COUNTER != `V_DISPLAY;
				V_DISPLAY	<= V_COUNTER == `V_DISPLAY;
				V_PULSE	<= 0;
			end else if(V_PULSE) begin
				V_BACK		<= V_COUNTER == `V_BACK;
				V_DISPLAY	<= 0;
				V_PULSE	<= V_COUNTER != `V_BACK;
			end else begin
				V_BACK		<= 0;
				V_DISPLAY	<= 0;
				V_PULSE	<= V_COUNTER == `V_PULSE;
			end
		end
	end


endmodule // VGA
