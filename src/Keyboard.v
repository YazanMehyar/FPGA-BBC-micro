module Keyboard (
	input clk1MHz,
	input clk2MHz,
	input nRESET,
	input autoscan,
	input [3:0] column,
	input [2:0] row,

	input PS2_CLK,
	input PS2_DATA,

	output column_match,
	output row_match);

	wire [7:0] DATA;
	wire DONE;
/****************************************************************************************/
	// 32 divider enable
	// to be driven by 1MHz clock ~ 30 KHz
	reg [12:0] CLKCOUNTER;
	reg En;

	always @ (posedge CLK) begin
		if(~nRESET) CLKCOUNTER <= 0;
		else		CLKCOUNTER <= CLKCOUNTER + 1;
	end

	always @ (posedge CLK) begin
		if(~nRESET)					En <= 0;
		else if(~|CLKCOUNTER[4:0])	En <= 1;
		else						En <= 0;
	end

	PS2_DRIVER p(
		.CLK(clk1MHz),
		.nRESET(nRESET),
		.En(En),
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		.DONE(DONE),
		.DATA(DATA));

/****************************************************************************************/

	reg [7:0] KEYMAP [0:15];
	reg [3:0] CLEAR_COUNTER = 0;
	reg [3:0] COL_COUNTER;

	always @ (posedge clk1MHz)
		CLEAR_COUNTER <= CLEAR_COUNTER + 1;

	always @ (posedge clk1MHz) begin
		if(~nRESET) COL_COUNTER <= 0;
		else		COL_COUNTER <= COL_COUNTER + 1;
	end

	reg [6:0] BBC_CODE; // Combinitorial
	always @ ( * ) begin
		case (DATA)
			8'h01: BBC_CODE = 7'h70; //ESC
			8'h02: BBC_CODE = 7'h30; // 1
			8'h03: BBC_CODE = 7'h31; // 2
			8'h04: BBC_CODE = 7'h11; // 3
			8'h05: BBC_CODE = 7'h12; // 4
			8'h06: BBC_CODE = 7'h13; // 5
			8'h07: BBC_CODE = 7'h34; // 6
			8'h08: BBC_CODE = 7'h24; // 7
			8'h09: BBC_CODE = 7'h15; // 8
			8'h0A: BBC_CODE = 7'h26; // 9
			8'h0B: BBC_CODE = 7'h27; // 0
			8'h0C: BBC_CODE = 7'h17; // - / _ to - / =

			8'h0E: BBC_CODE = 7'h59; // Backspace to DEL
			8'h0F: BBC_CODE = 7'h60; // tab
			8'h10: BBC_CODE = 7'h10; // q
			8'h11: BBC_CODE = 7'h21; // w
			8'h12: BBC_CODE = 7'h22; // e
			8'h13: BBC_CODE = 7'h33; // r
			8'h14: BBC_CODE = 7'h23; // t
			8'h15: BBC_CODE = 7'h44; // y
			8'h16: BBC_CODE = 7'h35; // u
			8'h17: BBC_CODE = 7'h25; // i
			8'h18: BBC_CODE = 7'h36; // o
			8'h19: BBC_CODE = 7'h37; // p
			8'h1A: BBC_CODE = 7'h38; // [ / {
			8'h1B: BBC_CODE = 7'h58; // ] / }
			8'h1C: BBC_CODE = 7'h49; // RET
			8'h1D: BBC_CODE = 7'h01; // LEFT CTRL

			8'h1E: BBC_CODE = 7'h41; // a
			8'h1F: BBC_CODE = 7'h51; // s
			8'h20: BBC_CODE = 7'h32; // d
			8'h21: BBC_CODE = 7'h43; // f
			8'h22: BBC_CODE = 7'h53; // g
			8'h23: BBC_CODE = 7'h54; // h
			8'h24: BBC_CODE = 7'h45; // j
			8'h25: BBC_CODE = 7'h46; // k
			8'h26: BBC_CODE = 7'h56; // l
			8'h27: BBC_CODE = 7'h67; // ; / : to ; / +
			8'h28: BBC_CODE = 7'h28; // ' / " to _ / <pound>
			8'h29: BBC_CODE = 7'h18; // ` / ~ to ^ / ~
			8'h2A: BBC_CODE = 7'h00; // LEFT SHIFT
			8'h2B: BBC_CODE = 7'h78; // \ / |

			8'h2C: BBC_CODE = 7'h61; // z
			8'h2D: BBC_CODE = 7'h42; // x
			8'h2E: BBC_CODE = 7'h52; // c
			8'h2F: BBC_CODE = 7'h63; // v
			8'h30: BBC_CODE = 7'h64; // b
			8'h31: BBC_CODE = 7'h55; // n
			8'h32: BBC_CODE = 7'h65; // m
			8'h33: BBC_CODE = 7'h66; // , / <
			8'h34: BBC_CODE = 7'h67; // . / >
			8'h35: BBC_CODE = 7'h68; // / / ?
			8'h36: BBC_CODE = 7'h00; // RIGHT SHIFT
			8'h38: BBC_CODE = 7'h50; // LEFT ALT to SHIFT LOCK
			8'h39: BBC_CODE = 7'h62; // SPACE
			8'h3A: BBC_CODE = 7'h40; // CAPS LOCK

			8'h3B: BBC_CODE = 7'h71; // f1
			8'h3C: BBC_CODE = 7'h72; // f2
			8'h3D: BBC_CODE = 7'h73; // f3
			8'h3E: BBC_CODE = 7'h14; // f4
			8'h3F: BBC_CODE = 7'h74; // f5
			8'h40: BBC_CODE = 7'h75; // f6
			8'h41: BBC_CODE = 7'h16; // f7
			8'h42: BBC_CODE = 7'h76; // f8
			8'h43: BBC_CODE = 7'h77; // f9
			8'h44: BBC_CODE = 7'h20; // f0

			8'h48: BBC_CODE = 7'h39; // UP ARROW
			8'h4B: BBC_CODE = 7'h19; // LEFT ARROW
			8'h4D: BBC_CODE = 7'h79; // RIGHT ARROW
			8'h50: BBC_CODE = 7'h29; // DOWN ARROW
			8'h4F: BBC_CODE = 7'h48; // END to : / *
			8'h47: BBC_CODE = 7'h47; // HOME to @
			8'h51: BBC_CODE = 7'h69; // PAGE DOWN to COPY
			default: BBC_CODE = 7'hxx;
		endcase
	end

	wire [3:0] BBC_COL = BBC_CODE[3:0];
	wire [7:0] BBC_ROW = 8'h01 << BBC_CODE[6:4];

	wire RAM_En = En&DONE | ~nRESET | ~|CLKCOUNTER[12:4];
	wire [3:0] RAM_WADR  = En&DONE? BBC_COL : CLEAR_COUNTER;
	wire [7:0] RAM_WDATA = En&DONE? BBC_ROW : 8'h00;
	wire [3:0] RAM_RADR  = autoscan? COL_COUNTER : column;
	reg  [7:0] RAM_RDATA;
	always @ (posedge clk2MHz) begin
		if(RAM_En&clk1MHz)	KEYMAP[RAM_WADR] <= RAM_WDATA;
		else if(~clk1MHz)	RAM_RDATA <= KEYMAP[RAM_RADR];
	end

/****************************************************************************************/

	assign column_match = |RAM_RDATA;
	assign row_match = RAM_RDATA & (8'h01 << row);

endmodule // Keyboard
