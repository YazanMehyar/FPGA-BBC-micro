`include "TOP.vh"

module BEEB_test();

	event START_LOG;
	initial begin
		@(START_LOG);
		$dumpvars(0, BEEB_test);
	end

	reg CLK100MHZ = 0;
	always #(`CLKPERIOD/2) CLK100MHZ = ~CLK100MHZ;


	// Simulate PS2_CLK
	reg [11:0] PS2_COUNT = 0;
	always @ (posedge CLK100MHZ) PS2_COUNT <= PS2_COUNT + 1;
	wire PS2_CLK = PS2_COUNT[11];

	// Simulate 16MHz enable from 100 MHz clock
	reg [2:0] COUNT6 = 0;
	always @ (posedge CLK100MHZ) 
		if(COUNT6 == 3'h5)	COUNT6 <= 0;
		else				COUNT6 <= COUNT6 + 1;
		
	// Simulate 6MHz enable from 100MHz clock
	reg [3:0] COUNT16 = 0;
	always @ (posedge CLK100MHZ) COUNT16 <= COUNT16 + 1;
	
	wire CLK_16en = COUNT6  == 0;
	wire CLK_6en  = COUNT16 == 0;

	// input
	reg nRESET;
	reg PS2_DATA;
	reg rMISO;

	// output
	wire [2:0] RGB;
	wire HSYNC;
	wire VSYNC;
	wire FIELD;
	wire SCK;
	wire MOSI;
	wire MISO;

	assign MISO = rMISO;
	always @ (posedge PS2_CLK) begin
		rMISO <= $urandom_range(0,5)/5;
	end

	BBC_MICRO beeb(
		.CLK(CLK100MHZ),
		.CLK_16en(CLK_16en),
		.CLK_6en(CLK_6en),
		.nRESET(nRESET),
		
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		
		.RGB(RGB),
		.HSYNC(HSYNC),
		.VSYNC(VSYNC),
		.FIELD(FIELD),
		
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
		.MOSI(MOSI)
	);

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

			@(posedge PS2_CLK); repeat (1000) @(posedge CLK100MHZ);
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

			repeat (4) @(posedge VSYNC);

			@(posedge PS2_CLK);
				PS2_SEND(8'hF0);
				PS2_SEND(KEY);

			repeat (2) @(posedge VSYNC);
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

/******************************************************************************/

	initial begin
		$start_screen;
		-> START_LOG;
		nRESET <= 0;
		PS2_DATA <= 1;
		repeat (100) @(posedge CLK100MHZ);
		nRESET <= 1;
		repeat (20) @(posedge VSYNC);
		$stop;
		$finish;
	end

/******************************************************************************/
// SD_card

	reg [47:0] CMD;
	integer CMD_count = 48;
	always @ (posedge SCK) begin
		CMD <= {CMD[46:0], MOSI};
		if(CMD_count != 0)
			CMD_count <= CMD_count - 1;
		else if(CMD[47:46] == 2'b01 && CMD[0]) begin
			$display("COMMAND: %D\nArgument: %H\nCRC: %H",CMD[45:40],CMD[39:8],CMD[7:0]);
			CMD_count <= 47;
		end
	end

	integer SCREEN_COUNT = 0;
	always @ (negedge VSYNC) begin
		$display("SCREEN No. %d", SCREEN_COUNT);
		SCREEN_COUNT <= SCREEN_COUNT + 1;
	end

/******************************************************************************/
// Virtual Screen

	reg [7:0] colour;
	always @ ( * ) begin
		case(RGB)
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

	initial forever begin
		@(negedge VSYNC)
		repeat (24) @(negedge HSYNC);
		repeat (160) @(posedge CLK_16en);
		$iv_sync(FIELD);
	end

	initial forever begin
		@(negedge HSYNC)
		repeat (160) @(posedge CLK_16en);
		$ih_sync;
	end

	always @(negedge CLK_16en) $pixel_scan(colour);

endmodule
