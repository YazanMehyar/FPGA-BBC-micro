`include "TOP.vh"

module TOP_test();

	event START_LOG;
	initial begin
		@(START_LOG);
		$dumpvars(0, TOP_test);
	end

	reg CLK50MHZ = 0;
	always #(`CLKPERIOD) CLK50MHZ = ~CLK50MHZ;

	// Simulate PS2_CLK
	reg [10:0] PS2_COUNT = 0;
	always @ (posedge CLK50MHZ) PS2_COUNT <= PS2_COUNT + 1;
	wire PS2_CLK = PS2_COUNT[10];

	// Task to simplify sending data via PS2
	task PS2_SEND;
		input [7:0] DATA;
		begin
			@(posedge PS2_CLK); repeat (500) @(posedge CLK50MHZ);
			PS2_DATA <= 1'b0;

			repeat (8) begin
				@(posedge PS2_CLK); repeat (500) @(posedge CLK50MHZ);
				PS2_DATA <= DATA[0];
				DATA <= {DATA[0],DATA[7:1]};
			end

			@(posedge PS2_CLK); repeat (500) @(posedge CLK50MHZ);
			PS2_DATA <= ^DATA;

			@(posedge PS2_CLK); repeat (500) @(posedge CLK50MHZ);
			PS2_DATA <= 1'b1;
			@(posedge PS2_CLK);
		end
	endtask

	task PRESS_KEY;
		input [7:0] KEY;
		begin
			@(posedge PS2_CLK);
				PS2_SEND(KEY);
				$display("PRINTING %H", KEY);

			@(posedge VGA_VS)

			@(posedge PS2_CLK);
				PS2_SEND(8'hF0);
				PS2_SEND(KEY);

			@(posedge VGA_VS);
		end
	endtask

	task MODE;
		input [2:0] MODE_No;
		begin
			PRESS_KEY(8'h3A);
			PRESS_KEY(8'h44);
			PRESS_KEY(8'h23);
			PRESS_KEY(8'h24);
			case (MODE_No)
				0: PRESS_KEY(8'h45);
				1: PRESS_KEY(8'h16);
				2: PRESS_KEY(8'h1E);
				3: PRESS_KEY(8'h26);
				4: PRESS_KEY(8'h25);
				5: PRESS_KEY(8'h2E);
				6: PRESS_KEY(8'h36);
				7: PRESS_KEY(8'h3D);
				default: $display("UNSUPPORTED MODE");
			endcase
			PRESS_KEY(8'h5A);
		end
	endtask


/**************************************************************************************************/
	// input
	reg CPU_RESETN;
	reg PS2_DATA;

	// output
	wire [3:0] VGA_R;
	wire [3:0] VGA_G;
	wire [3:0] VGA_B;
	wire VGA_HS;
	wire VGA_VS;
	wire SCK;
	wire MOSI;
	wire MISO;

	TOP top(
		.CLK100MHZ(CLK50MHZ),
		.CPU_RESETN(CPU_RESETN),
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		.VGA_B(VGA_B),
		.VGA_G(VGA_G),
		.VGA_R(VGA_R),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.SW(5'h01),
		.BTNU(1'b0),
		.BTND(1'b0),
		.BTNR(1'b0),
		.BTNL(1'b0),
		.BTNC(1'b0),
//		.JOYSTICK_D(4'hF),
//		.JOYSTICK_F(2'b11),
		.SCK(SCK),
		.MISO(MISO),
		.MOSI(MOSI)
	);

/**************************************************************************************************/

	initial begin
		$start_screen(800,600);
		CPU_RESETN <= 0;
		repeat (100) @(posedge CLK50MHZ);
		CPU_RESETN <= 1;
		@(posedge VGA_VS)
		-> START_LOG;
		repeat (6) @(posedge VGA_VS);
		repeat (100) @(posedge CLK50MHZ);
		$stop;
		$finish;
	end

/**************************************************************************************************/
// Virtual Screen
	wire [2:0] PIXEL = {VGA_B[0],VGA_G[0],VGA_R[0]};
	wire  PIXEL_CLK = CLK50MHZ;

	reg [7:0] colour;
	always @ ( * ) begin
		case(PIXEL)
			0: colour = 0;
			1: colour = 8'h03;
			2: colour = 8'h1C;
			3: colour = 8'h1F;
			4: colour = 8'hE0;
			5: colour = 8'hE3;
			6: colour = 8'hFC;
			7: colour = 8'hFF;
		endcase
	end

	integer SCREEN_COUNT = 0;
	always @ (negedge VGA_VS) begin
		$display("BBC SCREEN No. %d", SCREEN_COUNT);
		SCREEN_COUNT <= SCREEN_COUNT + 1;
	end

	integer VGA_SCREEN_COUNT = 0;
	always @ (negedge VGA_VS) begin
		$display("VGA SCREEN No. %d", VGA_SCREEN_COUNT);
		VGA_SCREEN_COUNT <= VGA_SCREEN_COUNT + 1;
	end

	initial forever begin
		@(negedge VGA_VS)
		repeat (31) @(negedge VGA_HS);
		repeat (40) @(posedge PIXEL_CLK);
		$v_sync;
	end

	initial forever begin
		@(negedge VGA_HS)
		repeat (40) @(posedge PIXEL_CLK);
		$h_sync;
	end

	always @(negedge PIXEL_CLK) $pixel_scan(colour);

endmodule
