module VGA (
	input nRESET,
	input PIXELCLK,
	output reg VGA_HSYNC,
	output reg VGA_VSYNC,
	output NEWLINE,
	output NEWSCREEN,
	output reg DISEN
	);

	`define H_COUNT_INIT 655
	`define H_PULSE_INIT 95
	`define H_BACKPORCH  47

	`define V_COUNT_INIT 490
	`define V_PULSE_INIT 1
	`define V_BACKPORCH  30
	
	`define PIXELS 640
	`define LINES  480

	wire ENDofLINE = H_DPHASE & ~|H_DELAY;
	wire ENDofSCREEN = ENDofLINE & V_DPHASE & ~|V_DELAY;
	
	assign NEWLINE = H_COUNTER == `PIXELS;
	assign NEWSCREEN = V_COUNTER == `LINES;

	// H_SYNC @ 31.46 KHz
	reg [9:0] H_COUNTER;
	reg [6:0] H_PULSE;
	reg [5:0] H_DELAY;
	reg H_DPHASE;
	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) begin
			H_COUNTER <= `H_COUNT_INIT;
			H_PULSE   <= `H_PULSE_INIT;
			H_DELAY   <= `H_BACKPORCH;
			VGA_HSYNC <=  0;
			H_DPHASE  <=  0;
		end else if(H_DPHASE) begin
			H_COUNTER <= `H_COUNT_INIT;
			H_PULSE   <= `H_PULSE_INIT;
			H_DELAY   <=  H_DELAY - 1;
			VGA_HSYNC <=  0;
			H_DPHASE  <= |H_DELAY;
		end else if(VGA_HSYNC) begin
			H_COUNTER <= `H_COUNT_INIT;
			H_PULSE   <=  H_PULSE - 1;
			H_DELAY   <= `H_BACKPORCH;
			VGA_HSYNC <= |H_PULSE;
			H_DPHASE  <= ~|H_PULSE;
		end else begin
			H_COUNTER <=  H_COUNTER - 1;
			H_PULSE   <= `H_PULSE_INIT;
			H_DELAY   <= `H_BACKPORCH;
			VGA_HSYNC <= ~|H_COUNTER;
			H_DPHASE  <=  0;
		end
	end

	// V_SYNC @ 60Hz
	reg [8:0] V_COUNTER;
	reg [1:0] V_PULSE;
	reg [4:0] V_DELAY;
	reg V_DPHASE;
	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) begin
			V_COUNTER <= `V_COUNT_INIT;
			V_PULSE   <= `V_PULSE_INIT;
			V_DELAY   <= `V_BACKPORCH;
			VGA_VSYNC <=  0;
			V_DPHASE  <=  0;
		end if(ENDofLINE) begin
			if(V_DPHASE) begin
				V_COUNTER <= `V_COUNT_INIT;
				V_PULSE   <= `V_PULSE_INIT;
				V_DELAY   <=  V_DELAY - 1;
				VGA_VSYNC <=  0;
				V_DPHASE  <= |V_DELAY;
			end else if(VGA_VSYNC) begin
				V_COUNTER <= `V_COUNT_INIT;
				V_PULSE   <=  V_PULSE - 1;
				V_DELAY   <= `V_BACKPORCH;
				VGA_VSYNC <= |V_PULSE;
				V_DPHASE  <= ~|V_PULSE;
			end else begin
				V_COUNTER <=  V_COUNTER - 1;
				V_PULSE   <= `V_PULSE_INIT;
				V_DELAY   <= `V_BACKPORCH;
				VGA_VSYNC <= ~|V_COUNTER;
				V_DPHASE  <=  0;
			end
		end
	end
	
	reg V_DISEN;
	always @ ( posedge PIXELCLK ) begin
		if(~nRESET) begin
			V_DISEN <= 0;
			DISEN   <= 0;
		end else begin
			if(NEWSCREEN & ENDofLINE)
				V_DISEN <= 1;
			else if(~|V_COUNTER)
				V_DISEN <= 0;
			
			if(V_DISEN && NEWLINE)
				DISEN <= 1;
			else if(~|H_COUNTER)
				DISEN <= 0;
		end
	end
	

endmodule // VGA
