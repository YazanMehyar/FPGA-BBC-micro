module Keyboard (
	input CLK_hPROC,
	input nRESET,
	input autoscan,
	input [3:0] column,
	input [2:0] row,

	input PS2_CLK,
	input PS2_DATA,

	output column_match,
	inout  row_match);

	wire [7:0] DATA;
	wire DONE;
/****************************************************************************************/

	PS2_DRIVER p(
		.CLK(CLK_hPROC),
		.nRESET(nRESET),
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		.DONE(DONE),
		.DATA(DATA));

/****************************************************************************************/

	reg [3:0] COL_COUNTER;
	always @ (posedge CLK_hPROC) begin
        if(COL_COUNTER == 9)
            COL_COUNTER <= 0;
        else
            COL_COUNTER <= COL_COUNTER + 1;
            
	end

	reg [6:0] BBC_CODE; // Combinitorial
	always @ ( * ) begin
		case (DATA)
			8'h76: BBC_CODE = 7'h70; //ESC
			8'h16: BBC_CODE = 7'h30; // 1
			8'h1E: BBC_CODE = 7'h31; // 2
			8'h26: BBC_CODE = 7'h11; // 3
			8'h25: BBC_CODE = 7'h12; // 4
			8'h2E: BBC_CODE = 7'h13; // 5
			8'h36: BBC_CODE = 7'h34; // 6
			8'h3D: BBC_CODE = 7'h24; // 7
			8'h3E: BBC_CODE = 7'h15; // 8
			8'h46: BBC_CODE = 7'h26; // 9
			8'h45: BBC_CODE = 7'h27; // 0
			8'h4E: BBC_CODE = 7'h17; // - / _ to - / =

			8'h66: BBC_CODE = 7'h59; // Backspace to DEL
			8'h0D: BBC_CODE = 7'h60; // tab
			8'h15: BBC_CODE = 7'h10; // q
			8'h1D: BBC_CODE = 7'h21; // w
			8'h24: BBC_CODE = 7'h22; // e
			8'h2D: BBC_CODE = 7'h33; // r
			8'h2C: BBC_CODE = 7'h23; // t
			8'h35: BBC_CODE = 7'h44; // y
			8'h3C: BBC_CODE = 7'h35; // u
			8'h43: BBC_CODE = 7'h25; // i
			8'h44: BBC_CODE = 7'h36; // o
			8'h4D: BBC_CODE = 7'h37; // p
			8'h54: BBC_CODE = 7'h38; // [ / {
			8'h5B: BBC_CODE = 7'h58; // ] / }
			8'h5A: BBC_CODE = 7'h49; // RET
			8'h14: BBC_CODE = 7'h01; // LEFT CTRL

			8'h1C: BBC_CODE = 7'h41; // a
			8'h1B: BBC_CODE = 7'h51; // s
			8'h23: BBC_CODE = 7'h32; // d
			8'h2B: BBC_CODE = 7'h43; // f
			8'h34: BBC_CODE = 7'h53; // g
			8'h33: BBC_CODE = 7'h54; // h
			8'h3B: BBC_CODE = 7'h45; // j
			8'h42: BBC_CODE = 7'h46; // k
			8'h4B: BBC_CODE = 7'h56; // l
			8'h4C: BBC_CODE = 7'h67; // ; / : to ; / +
			8'h52: BBC_CODE = 7'h28; // ' / " to _ / <pound>
			8'h0E: BBC_CODE = 7'h18; // ` / ~ to ^ / ~
			8'h12: BBC_CODE = 7'h00; // LEFT SHIFT
			8'h61: BBC_CODE = 7'h78; // \ / | UK keyboard

			8'h1A: BBC_CODE = 7'h61; // z
			8'h22: BBC_CODE = 7'h42; // x
			8'h21: BBC_CODE = 7'h52; // c
			8'h2A: BBC_CODE = 7'h63; // v
			8'h32: BBC_CODE = 7'h64; // b
			8'h31: BBC_CODE = 7'h55; // n
			8'h3A: BBC_CODE = 7'h65; // m
			8'h41: BBC_CODE = 7'h66; // , / <
			8'h49: BBC_CODE = 7'h67; // . / >
			8'h4A: BBC_CODE = 7'h68; // / / ?
			8'h59: BBC_CODE = 7'h00; // RIGHT SHIFT
			8'h11: BBC_CODE = 7'h50; // LEFT ALT to SHIFT LOCK
			8'h29: BBC_CODE = 7'h62; // SPACE
			8'h58: BBC_CODE = 7'h40; // CAPS LOCK

			8'h05: BBC_CODE = 7'h71; // f1
			8'h06: BBC_CODE = 7'h72; // f2
			8'h04: BBC_CODE = 7'h73; // f3
			8'h0C: BBC_CODE = 7'h14; // f4
			8'h03: BBC_CODE = 7'h74; // f5
			8'h0B: BBC_CODE = 7'h75; // f6
			8'h83: BBC_CODE = 7'h16; // f7
			8'h0A: BBC_CODE = 7'h76; // f8
			8'h01: BBC_CODE = 7'h77; // f9
			8'h09: BBC_CODE = 7'h20; // f10 to f0

			8'h75: BBC_CODE = 7'h39; // UP ARROW
			8'h6B: BBC_CODE = 7'h19; // LEFT ARROW
			8'h74: BBC_CODE = 7'h79; // RIGHT ARROW
			8'h72: BBC_CODE = 7'h29; // DOWN ARROW
			8'h55: BBC_CODE = 7'h48; // = / + to : / *
			8'h78: BBC_CODE = 7'h47; // F11 to @
			8'h07: BBC_CODE = 7'h69; // F12 to COPY
			default: BBC_CODE = 7'hxE;
		endcase
	end
	
	reg KEY_RELEASE;
	reg [7:0] KEY_MAP [0:15];
	always @ (posedge CLK_hPROC) begin
	   if(nRESET) begin
	       KEY_RELEASE <= 0;
	       KEY_MAP[0] <= 8'h0;
	       KEY_MAP[1] <= 8'h0;
	       KEY_MAP[2] <= 8'h0;
	       KEY_MAP[3] <= 8'h0;
	       KEY_MAP[4] <= 8'h0;
	       KEY_MAP[5] <= 8'h0;
	       KEY_MAP[6] <= 8'h0;
	       KEY_MAP[7] <= 8'h0;
	       KEY_MAP[8] <= 8'h0;
	       KEY_MAP[9] <= 8'h0;
	       KEY_MAP[10] <= 8'h0;
	       KEY_MAP[11] <= 8'h0;
	       KEY_MAP[12] <= 8'h0;
	       KEY_MAP[13] <= 8'h0;
	       KEY_MAP[14] <= 8'h0;
	       KEY_MAP[15] <= 8'h0;
	   end else if(DONE) begin
	       if(DATA == 8'hF0)
	           KEY_RELEASE <= 1;
	       else begin
	           KEY_RELEASE <= 0;
	           case(BBC_CODE[6:4])
	               3'b000: KEY_MAP[BBC_CODE[3:0]] <= KEY_RELEASE? 8'h00 : 8'h01;
	               3'b001: KEY_MAP[BBC_CODE[3:0]] <= KEY_RELEASE? 8'h00 : 8'h02;
	               3'b010: KEY_MAP[BBC_CODE[3:0]] <= KEY_RELEASE? 8'h00 : 8'h04;
	               3'b011: KEY_MAP[BBC_CODE[3:0]] <= KEY_RELEASE? 8'h00 : 8'h08;
	               3'b100: KEY_MAP[BBC_CODE[3:0]] <= KEY_RELEASE? 8'h00 : 8'h10;
	               3'b101: KEY_MAP[BBC_CODE[3:0]] <= KEY_RELEASE? 8'h00 : 8'h20;
	               3'b110: KEY_MAP[BBC_CODE[3:0]] <= KEY_RELEASE? 8'h00 : 8'h40;
	               3'b111: KEY_MAP[BBC_CODE[3:0]] <= KEY_RELEASE? 8'h00 : 8'h80;
	           endcase
	       end
	   end
	end
	
	wire [3:0] kCOLUMN = autoscan? COL_COUNTER : column; 
	wire [7:0] kROW    = KEY_MAP[kCOLUMN];


/****************************************************************************************/

	assign column_match = |BBC_ROW & (autoscan? COL_COUNTER == BBC_COL : (column <= 9) && column == BBC_COL);
	assign row_match    = autoscan? 1'bz : BBC_ROW == row;

endmodule // Keyboard
