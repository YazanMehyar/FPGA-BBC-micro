`include "TOP.vh"

module TOP_test();

	//initial $dumpvars(3, TOP_test);

	reg CLK100MHZ = 0;
	always #(`CLKPERIOD/2) CLK100MHZ = ~CLK100MHZ;


	// Simulate PS2_CLK
	reg [11:0] PS2_COUNT = 0;
	always @ ( posedge CLK100MHZ ) PS2_COUNT <= PS2_COUNT + 1;
	wire PS2_CLK = PS2_COUNT[11];

	// Simulate PIXELCLK
	reg [1:0] PIXELCOUNT = 0;
	always @ ( posedge CLK100MHZ ) PIXELCOUNT <= PIXELCOUNT + 1;
	wire PIXELCLK = PIXELCOUNT[0];

	// input
	reg CPU_RESETN;
	reg PS2_DATA;
	wire SD_DAT = 1'b0;

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

	// Task to simplify sending data via PS2
	task PS2_SEND;
		input [7:0] DATA;
		begin
			@(posedge PS2_CLK); repeat (1000) @(posedge CLK100MHZ);
			PS2_DATA <= 1'b0;

			repeat (8) begin
				@(posedge PS2_CLK); repeat (1000) @(posedge CLK100MHZ);
				PS2_DATA <= DATA[0];
				DATA <= {DATA[0],DATA[7:1]};
			end

			@(posedge PS2_CLK); repeat (1000) @(posedge CLK100MHZ);
			PS2_DATA <= ^DATA;

			@(posedge PS2_CLK);repeat (1000) @(posedge CLK100MHZ);
			PS2_DATA <= 1'b1;
			@(posedge PS2_CLK);
		end
	endtask

	task PRESS_KEY;
		input [7:0] KEY;
		begin
			@(posedge PS2_CLK);
				PS2_SEND(KEY);
				//$display("PRINTING %H", KEY);
			@(posedge VGA_VS);

			@(posedge PS2_CLK);
				PS2_SEND(8'hF0);
				PS2_SEND(KEY);
			repeat (2)	@(posedge VGA_VS);
		end
	endtask

	task MODE;
		input [2:0] MODE_No;
		begin
			PRESS_KEY(8'h3A);
			PRESS_KEY(8'h44);
			PRESS_KEY(8'h23);
			PRESS_KEY(8'h24);
			PRESS_KEY(8'h29);
			case (MODE_No)
				0: PRESS_KEY(8'h45);
				1: PRESS_KEY(8'h16);
				2: PRESS_KEY(8'h1E);
				3: PRESS_KEY(8'h26);
				4: PRESS_KEY(8'h25);
				5: PRESS_KEY(8'h2E);
				6: PRESS_KEY(8'h36);
				default: $display("UNSUPPORTED MODE");
			endcase
			PRESS_KEY(8'h5A);
		end
	endtask

/******************************************************************************/

	initial begin
		$start_screen;

		CPU_RESETN <= 0;
		PS2_DATA <= 1;
		repeat (100) @(posedge CLK100MHZ);

		CPU_RESETN <= 1;
		repeat (72) @(posedge VGA_VS);
		$stop;

		// Send some keys
		//MODE(4);
		PRESS_KEY(8'h1B);

		//$stop;
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
		repeat (31) @(negedge VGA_HS);
		repeat (48) @(posedge PIXELCLK);
		$v_sync;
	end

	initial forever begin
		@(negedge VGA_HS)
		repeat (48) @(posedge PIXELCLK);
		$h_sync;
	end

	always @(negedge PIXELCLK) $pixel_scan(colour);

endmodule
