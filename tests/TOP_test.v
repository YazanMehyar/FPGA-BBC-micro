`include "TOP.vh"

module TOP_test();

	initial $dumpvars(0, TOP_test);

	reg CLK100MHZ = 0;
	always #(`CLKPERIOD/2) CLK100MHZ = ~CLK100MHZ;


	// Simulate PS2_CLK
	reg [14:0] PS2_COUNT = 0;
	always @ ( posedge CLK100MHZ ) PS2_COUNT <= PS2_COUNT + 1;
	wire PS2_CLK = PS2_COUNT[14];

	// Simulate PIXELCLK
	reg [1:0] PIXELCOUNT = 0;
	always @ ( posedge CLK100MHZ ) PIXELCOUNT <= PIXELCOUNT + 1;
	wire PIXELCLK = PIXELCOUNT[1];

	// input
	reg CPU_RESETN;
	reg PS2_DATA;

	// output
	wire [3:0] VGA_R;
	wire [3:0] VGA_G;
	wire [3:0] VGA_B;
	wire VGA_HS;
	wire VGA_VS;

	TOP top(
		.CLK100MHZ(CLK100MHZ),
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		.CPU_RESETN(CPU_RESETN),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS));

/******************************************************************************/

	`include "TEST_HELPERS.vh"

	initial begin
		$start_screen;

		CPU_RESETN <= 0;
		PS2_DATA <= 1;
		repeat (16) @(posedge CLK100MHZ);

		CPU_RESETN <= 1;
		repeat (2) @(posedge VGA_VS);

		// Send some keys
		PRESS_KEY(8'h4D);
		PRESS_KEY(8'h2D);
		PRESS_KEY(8'h43);
		PRESS_KEY(8'h31);
		PRESS_KEY(8'h2C);
		PRESS_KEY(8'h29);
		PRESS_KEY(8'h3D);
		PRESS_KEY(8'h29);
		PRESS_KEY(8'h4E);
		PRESS_KEY(8'h29);
		PRESS_KEY(8'h26);
		PRESS_KEY(8'h5A);
		PRESS_KEY(8'h4D);

		@(posedge VGA_VS);

		$stop;
		$finish;
	end

	integer SCREEN_COUNT = 0;
	always @ (posedge VGA_VS) begin
		$display("SCREEN No. %d", SCREEN_COUNT);
		SCREEN_COUNT <= SCREEN_COUNT + 1;
	end

/******************************************************************************/

	reg [7:0] colour;
	always @ ( * ) begin
		case({VGA_R[0],VGA_G[0],VGA_B[0]})
			0: colour = 0;
			1: colour = 8'h03;
			2: colour = 8'h1C;
			3: colour = 8'h1F;
			4: colour = 8'hE0;
			5: colour = 8'hE3;
			6: colour = 8'hFC;
			7: colour = 8'hFF;
			default: colour = 8'hxx;
		endcase
	end

// Virtual Screen
	initial forever begin
		@(negedge VGA_VS)
		repeat (33) @(negedge VGA_HS);
		$v_sync;
	end

	initial forever begin
		@(negedge VGA_HS)
		repeat (48) @(posedge PIXELCLK);
		$h_sync;
	end

	always @(negedge PIXELCLK) $pixel_scan(colour);

endmodule
