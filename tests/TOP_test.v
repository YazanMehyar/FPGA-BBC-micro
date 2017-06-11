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
	always @ ( posedge CLK50MHZ ) PS2_COUNT <= PS2_COUNT + 1;
	wire PS2_CLK = PS2_COUNT[10];
	
	// Simulate 16MHz enable from 50 MHz clock
	reg [1:0] COUNT3 = 0;
	always @ (posedge CLK50MHZ) 
		if(COUNT3[1])	COUNT3 <= 0;
		else			COUNT3 <= COUNT3 + 1;
		
	// Simulate 6MHz enable from 50MHz clock
	reg [2:0] COUNT8 = 0;
	always @ (posedge CLK50MHZ) COUNT8 <= COUNT8 + 1;
	
	// Simulate VGA pixel scan rate
	
	wire CLK_16en = COUNT3 == 0;
	wire CLK_6en  = COUNT8 == 0;

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

			@(posedge VSYNC)

			@(posedge PS2_CLK);
				PS2_SEND(8'hF0);
				PS2_SEND(KEY);

			@(posedge VSYNC);
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
				default: $display("UNSUPPORTED MODE");
			endcase
			PRESS_KEY(8'h5A);
		end
	endtask


/**************************************************************************************************/
	// input
	reg nRESET;
	reg rMISO;
	reg PS2_DATA;

	wire VGA_NEWLINE;
	wire OUT_OF_SCREEN;
	
	// output
	wire [2:0] RGB;
	wire [2:0] DEBUG_RGB;
	wire HSYNC;
	wire VSYNC;
	wire SCK;
	wire MOSI;
	wire MISO;


	BBC_MICRO beeb(
		.CLK(CLK50MHZ),
		.CLK_16en(CLK_16en),
		.CLK_6en(CLK_6en),
		.nRESET(nRESET),
		
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		
		.RGB(RGB),
		.HSYNC(HSYNC),
		.VSYNC(VSYNC),
		
		.DISPLAY_DEBUGGER(1'b1),
		.DISABLE_INTERRUPTS(1'b0),
		.EN_BREAKPOINT(1'b0),
		.SET_BREAKPOINT(1'b0),
		
		.BUTTON_UP(1'b0),
		.BUTTON_DOWN(1'b0),
		.BUTTON_LEFT(1'b0),
		.BUTTON_RIGHT(1'b0),
		.BUTTON_STEP(1'b0),
		
		.SCK(SCK),
		.MISO(MISO),
		.MOSI(MOSI),
		
		.DEBUG_CLK(CLK50MHZ),
		.DEBUG_ENABLE(OUT_OF_SCREEN),
		.DEBUG_NEWLINE(VGA_NEWLINE),
		.DEBUG_RGB(DEBUG_RGB)
	);
	
	// output
	wire       VGA_VSYNC;
	wire       VGA_HSYNC;
	wire [2:0] VGA_RGB;
	
	VGA vga(
		.CLK(CLK50MHZ),
		.READ_en(1'b1),
		.WRITE_en(CLK_16en),
		.VSYNC(VSYNC),
		.HSYNC(HSYNC),
		.RGB(RGB),
		.VGA_HSYNC(VGA_HSYNC),
		.VGA_VSYNC(VGA_VSYNC),
		.VGA_RGB(VGA_RGB),
		.VGA_NEWLINE(VGA_NEWLINE),
		.OUT_OF_SCREEN(OUT_OF_SCREEN)
	);

/**************************************************************************************************/

	initial begin
		$start_screen;
		nRESET <= 0;
		repeat (100) @(posedge CLK50MHZ);
		nRESET <= 1;
		@(posedge VSYNC)
		-> START_LOG;
		repeat (2) @(posedge VSYNC);
		repeat (100) @(posedge CLK50MHZ);
		$stop;
		$finish;
	end

/**************************************************************************************************/
// Virtual Screen
	wire [2:0] PIXEL = OUT_OF_SCREEN? VGA_RGB^DEBUG_RGB : VGA_RGB;

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
	always @ (negedge VSYNC) begin
		$display("BBC SCREEN No. %d", SCREEN_COUNT);
		SCREEN_COUNT <= SCREEN_COUNT + 1;
	end
	
	integer VGA_SCREEN_COUNT = 0;
	always @ (negedge VGA_VSYNC) begin
		$display("VGA SCREEN No. %d", VGA_SCREEN_COUNT);
		VGA_SCREEN_COUNT <= VGA_SCREEN_COUNT + 1;
	end

	initial forever begin
		@(negedge VGA_VSYNC)
		repeat (31) @(negedge VGA_HSYNC);
		repeat (40) @(posedge CLK50MHZ);
		$v_sync;
	end

	initial forever begin
		@(negedge VGA_HSYNC)
		repeat (40) @(posedge CLK50MHZ);
		$h_sync;
	end

	always @(negedge CLK50MHZ) $pixel_scan(colour);

endmodule
