`include "TOP.vh"

module BEEB_test();

	event START_LOG;
	initial begin
		@(START_LOG);
		$dumpvars(0, BEEB_test);
	end

	reg CLK16MHZ = 0;
	always #(`CLKPERIOD) CLK16MHZ = ~CLK16MHZ;

	// Simulate PS2_CLK
	reg [8:0] PS2_COUNT = 0;
	always @ (posedge CLK16MHZ) PS2_COUNT <= PS2_COUNT + 1;
	wire PS2_CLK = PS2_COUNT[8];
		
	// Simulate 6MHz enable from 16MHz clock
	reg [3:0] COUNT16 = 0;
	always @ (posedge CLK16MHZ or negedge CLK16MHZ)
		COUNT16 <= COUNT16 + 1;
	
	wire CLK_16en = 1'b1;
	reg  CLK_6en;
	
	always @ (*) case (COUNT16)
		4'h0,4'hF,
		4'h4,4'h5,
		4'h9,4'hA:  CLK_6en = 1;
		default:	CLK_6en = 0;
	endcase
		

	// input
	reg nRESET;
	reg PS2_DATA;
	reg rMISO;

	// output
	wire [2:0] RGB;
	wire HSYNC;
	wire VSYNC;
	wire SCK;
	wire MOSI;
	wire MISO;

	assign MISO = rMISO;
	always @ (posedge PS2_CLK) begin
		rMISO <= $urandom_range(0,5)/5;
	end

	BBC_MICRO beeb(
		.CLK(CLK16MHZ),
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
		
		.DEBUG_CLK_en(1'b0),
		.DBUTTON_en(1'b0),
		.DEBUG_ENABLE(1'b0),
		.DEBUG_NEWLINE(1'b0)
	);

/******************************************************************************/

	// Task to simplify sending data via PS2
	task PS2_SEND;
		input [7:0] DATA;
		begin
			@(posedge PS2_CLK); repeat (150) @(posedge CLK16MHZ);
			PS2_DATA <= 1'b0;

			repeat (8) begin
				@(posedge PS2_CLK); repeat (150) @(posedge CLK16MHZ);
				PS2_DATA <= DATA[0];
				DATA <= {DATA[0],DATA[7:1]};
			end

			@(posedge PS2_CLK); repeat (150) @(posedge CLK16MHZ);
			PS2_DATA <= ^DATA;

			@(posedge PS2_CLK); repeat (150) @(posedge CLK16MHZ);
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
				7: PRESS_KEY(8'h3D);
				default: $display("UNSUPPORTED MODE");
			endcase
			PRESS_KEY(8'h5A);
		end
	endtask

/******************************************************************************/

	initial begin
		$start_screen(640,576);
		-> START_LOG;
		nRESET <= 0;
		PS2_DATA <= 1;
		repeat (20) @(posedge CLK16MHZ);
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
		repeat (170) @(posedge CLK16MHZ);
		$iv_sync;
	end

	initial forever begin
		@(negedge HSYNC)
		repeat (170) @(posedge CLK16MHZ);
		$ih_sync;
	end

	always @(negedge CLK16MHZ) $pixel_scan(colour);

endmodule
