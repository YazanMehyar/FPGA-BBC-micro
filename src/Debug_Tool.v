module Debug_Tool(
	input PIXELCLK,
	input VSYNC,
	input HSYNC,

	input [23:0] TAG1,
	input [23:0] TAG2,
	input [23:0] TAG3,
	input [23:0] TAG4,
	input [15:0] VAL1,
	input [15:0] VAL2,
	input [15:0] VAL3,
	input [15:0] VAL4,
	input [1:0]  PROBE_B,
	input [1:0]  TOOL_B,

	output [3:0] SEL1,
	output [3:0] SEL2,
	output [3:0] SEL3,
	output [3:0] SEL4,
	output PIXEL_OUT
	);

	`define CHAR_HEIGHT 9
	`define CHAR_WIDTH  7
	`ifdef SIMULATION
		`define DEBUG_LINE  400
	`else
		`define DEBUG_LINE  500
	`endif
	`define DEBUG_HLINE 63

	reg [5:0] CHAR_ADDR;
	reg [3:0] PIXEL_COUNT;
	reg [9:0] LINE_COUNT;
	reg [5:0] H_DISPLAY;
	reg [3:0] ROW_ADDRESS;
	reg [1:0] LINE;
	reg [3:0] Dsel;
	reg [4:0] Den;
	reg [3:0] PROBEen;
	reg HIGHLIGHT;

	wire NEXT_CHAR;
	wire NEG_HSYNC;
	wire BUTTON_NEXT;
	wire BUTTON_PREV;
	wire DEBUG_DISEN;
	wire UPDATE;

	wire [5:0] CHARADR1;
	wire [5:0] CHARADR2;
	wire [5:0] CHARADR3;
	wire [5:0] CHARADR4;

	`ifdef SIMULATION
		initial begin
			Den  = 0;
			Dsel = 0;
			ROW_ADDRESS = 0;
			PIXEL_COUNT = 0;
		end
	`endif

	Edge_Trigger #(0) HSYNC_NEG(.clk(PIXELCLK),.IN(HSYNC),.En(1'b1),.EDGE(NEG_HSYNC));
	Edge_Trigger #(1) POS_BUTTON0(.clk(PIXELCLK),.IN(TOOL_B[0]),.En(1'b1),.EDGE(BUTTON_NEXT));
	Edge_Trigger #(1) POS_BUTTON1(.clk(PIXELCLK),.IN(TOOL_B[1]),.En(1'b1),.EDGE(BUTTON_PREV));

	always @ ( posedge PIXELCLK )
		if(VSYNC)
			LINE_COUNT <= `DEBUG_LINE;
		else if(NEG_HSYNC & |LINE_COUNT)
			LINE_COUNT <= LINE_COUNT - 1;

	always @ (posedge PIXELCLK)
		if(HSYNC)
			H_DISPLAY <= `DEBUG_HLINE;
		else if(|H_DISPLAY)
			H_DISPLAY <=  H_DISPLAY - 1;

	always @ ( posedge PIXELCLK )
		if(~|PIXEL_COUNT | HSYNC)
			PIXEL_COUNT <= `CHAR_WIDTH;
		else if(DEBUG_DISEN)
			PIXEL_COUNT <= PIXEL_COUNT - 1;

	always @ ( posedge PIXELCLK )
		if(~|Dsel)
			Dsel <= 4'h1;
		else if(BUTTON_NEXT)
			Dsel <= {Dsel[2:0],Dsel[3]};
		else if(BUTTON_PREV)
			Dsel <= {Dsel[0],Dsel[3:1]};

	always @ (posedge PIXELCLK)
		if(VSYNC) begin
			ROW_ADDRESS <= 0;
			LINE <= 2'h2;
		end else if(HSYNC & DEBUG_DISEN)
			if(ROW_ADDRESS != `CHAR_HEIGHT)
				ROW_ADDRESS <= ROW_ADDRESS + 1;
			else begin
				ROW_ADDRESS <= 0;
				LINE <= LINE - 1;
			end

	always @ (posedge PIXELCLK)
		if(HSYNC)
			Den <= 0;
		else if(NEXT_CHAR & ~&Den)
			Den <= Den + 1;

	always @ (posedge PIXELCLK)
		if(NEXT_CHAR) HIGHLIGHT <= |(Dsel&PROBEen);

	always @ ( * )
		if(~Den[2]) case (Den[4:3])
			2'b00: begin CHAR_ADDR = CHARADR1; PROBEen = 4'h1;end
			2'b01: begin CHAR_ADDR = CHARADR2; PROBEen = 4'h2;end
			2'b10: begin CHAR_ADDR = CHARADR3; PROBEen = 4'h4;end
			2'b11: begin CHAR_ADDR = CHARADR4; PROBEen = 4'h8;end
			default: begin CHAR_ADDR = 6'h38; PROBEen = 4'h0; end
		endcase else begin CHAR_ADDR = 6'h38; PROBEen = 4'h0; end


/****************************************************************************************/
	assign DEBUG_DISEN = &{~|LINE_COUNT,~|H_DISPLAY,|LINE};
	assign NEXT_CHAR = ~|PIXEL_COUNT & DEBUG_DISEN;
	assign PIXEL_OUT = DEBUG_DISEN? HIGHLIGHT ~^ CHAR_SR[`CHAR_WIDTH] : 1'b0;
	assign UPDATE = |LINE_COUNT;

	Debug_Probe dp1(
		.PIXELCLK(PIXELCLK),
		.DEBUGen(PROBEen[0]),
		.SELen(Dsel[0]),
		.UPDATE(UPDATE),
		.VALUE(VAL1),
		.TAG(TAG1),
		.LINE(LINE[0]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(PROBE_B),
		.SEL(SEL1),
		.CHAR_ADDR(CHARADR1)
	);

	Debug_Probe dp2(
		.PIXELCLK(PIXELCLK),
		.DEBUGen(PROBEen[1]),
		.SELen(Dsel[1]),
		.UPDATE(UPDATE),
		.VALUE(VAL2),
		.TAG(TAG2),
		.LINE(LINE[0]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(PROBE_B),
		.SEL(SEL2),
		.CHAR_ADDR(CHARADR2)
	);

	Debug_Probe dp3(
		.PIXELCLK(PIXELCLK),
		.DEBUGen(PROBEen[2]),
		.SELen(Dsel[2]),
		.UPDATE(UPDATE),
		.VALUE(VAL3),
		.TAG(TAG3),
		.LINE(LINE[0]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(PROBE_B),
		.SEL(SEL3),
		.CHAR_ADDR(CHARADR3)
	);

	Debug_Probe dp4(
		.PIXELCLK(PIXELCLK),
		.DEBUGen(PROBEen[3]),
		.SELen(Dsel[3]),
		.UPDATE(UPDATE),
		.VALUE(VAL4),
		.TAG(TAG4),
		.LINE(LINE[0]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(PROBE_B),
		.SEL(SEL4),
		.CHAR_ADDR(CHARADR4)
	);

/****************************************************************************************/

	// Char ROM as big case statement
	reg [`CHAR_WIDTH:0] CHAR_SR;
	reg [`CHAR_WIDTH:0] CHAR_ROM;

	always @ (posedge PIXELCLK)
		if(NEXT_CHAR) CHAR_SR <= CHAR_ROM;
		else		  CHAR_SR <= {CHAR_SR[6:0],1'b1};

	always @ ( * )
		case (CHAR_ADDR[5:3])
		3'b000: case (ROW_ADDRESS)
			4'h0,`CHAR_HEIGHT: CHAR_ROM = 8'hFF;
			4'h1: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b11110111; 3'h2: CHAR_ROM = 8'b11000011; 3'h3: CHAR_ROM = 8'b11000011; 3'h4: CHAR_ROM = 8'b11111011; 3'h5: CHAR_ROM = 8'b10000001; 3'h6: CHAR_ROM = 8'b11100011; 3'h7: CHAR_ROM = 8'b10000001; default: CHAR_ROM = 8'hxx; endcase
			4'h2: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b11000111; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b11110011; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b11011111; 3'h7: CHAR_ROM = 8'b10111101; default: CHAR_ROM = 8'hxx; endcase
			4'h3: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b11110111; 3'h2: CHAR_ROM = 8'b11111101; 3'h3: CHAR_ROM = 8'b11111101; 3'h4: CHAR_ROM = 8'b11101011; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10111111; 3'h7: CHAR_ROM = 8'b11111101; default: CHAR_ROM = 8'hxx; endcase
			4'h4: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b11110111; 3'h2: CHAR_ROM = 8'b11111101; 3'h3: CHAR_ROM = 8'b11100011; 3'h4: CHAR_ROM = 8'b11011011; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10111111; 3'h7: CHAR_ROM = 8'b11111011; default: CHAR_ROM = 8'hxx; endcase
			4'h5: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10110101; 3'h1: CHAR_ROM = 8'b11110111; 3'h2: CHAR_ROM = 8'b11111011; 3'h3: CHAR_ROM = 8'b11100011; 3'h4: CHAR_ROM = 8'b10000001; 3'h5: CHAR_ROM = 8'b10000011; 3'h6: CHAR_ROM = 8'b10000011; 3'h7: CHAR_ROM = 8'b11110111; default: CHAR_ROM = 8'hxx; endcase
			4'h6: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b11110111; 3'h2: CHAR_ROM = 8'b11110111; 3'h3: CHAR_ROM = 8'b11111101; 3'h4: CHAR_ROM = 8'b11111011; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b11101111; default: CHAR_ROM = 8'hxx; endcase
			4'h7: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b11110111; 3'h2: CHAR_ROM = 8'b11101111; 3'h3: CHAR_ROM = 8'b11111101; 3'h4: CHAR_ROM = 8'b11111011; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b11011111; default: CHAR_ROM = 8'hxx; endcase
			4'h8: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b10000001; 3'h2: CHAR_ROM = 8'b10000001; 3'h3: CHAR_ROM = 8'b11000011; 3'h4: CHAR_ROM = 8'b11100001; 3'h5: CHAR_ROM = 8'b10000011; 3'h6: CHAR_ROM = 8'b11000011; 3'h7: CHAR_ROM = 8'b10111111; default: CHAR_ROM = 8'hxx; endcase
			default: CHAR_ROM = 8'hxx; endcase
		3'b001: case (ROW_ADDRESS)
			4'h0,`CHAR_HEIGHT: CHAR_ROM = 8'hFF;
			4'h1: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b11000011; 3'h2: CHAR_ROM = 8'b11000111; 3'h3: CHAR_ROM = 8'b10000011; 3'h4: CHAR_ROM = 8'b11000001; 3'h5: CHAR_ROM = 8'b10000111; 3'h6: CHAR_ROM = 8'b10000001; 3'h7: CHAR_ROM = 8'b10000001; default: CHAR_ROM = 8'hxx; endcase
			4'h2: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b10011111; 3'h5: CHAR_ROM = 8'b10111001; 3'h6: CHAR_ROM = 8'b10111111; 3'h7: CHAR_ROM = 8'b10111111; default: CHAR_ROM = 8'hxx; endcase
			4'h3: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11011011; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b10111111; 3'h5: CHAR_ROM = 8'b10111101; 3'h6: CHAR_ROM = 8'b10111111; 3'h7: CHAR_ROM = 8'b10111111; default: CHAR_ROM = 8'hxx; endcase
			4'h4: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b11000001; 3'h2: CHAR_ROM = 8'b11011011; 3'h3: CHAR_ROM = 8'b10000011; 3'h4: CHAR_ROM = 8'b10111111; 3'h5: CHAR_ROM = 8'b10111101; 3'h6: CHAR_ROM = 8'b10000011; 3'h7: CHAR_ROM = 8'b10111111; default: CHAR_ROM = 8'hxx; endcase
			4'h5: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b11111101; 3'h2: CHAR_ROM = 8'b10000001; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b10111111; 3'h5: CHAR_ROM = 8'b10111101; 3'h6: CHAR_ROM = 8'b10000011; 3'h7: CHAR_ROM = 8'b10000001; default: CHAR_ROM = 8'hxx; endcase
			4'h6: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b11111101; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b10111111; 3'h5: CHAR_ROM = 8'b10111101; 3'h6: CHAR_ROM = 8'b10111111; 3'h7: CHAR_ROM = 8'b10111111; default: CHAR_ROM = 8'hxx; endcase
			4'h7: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b11111011; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b10011111; 3'h5: CHAR_ROM = 8'b10111001; 3'h6: CHAR_ROM = 8'b10111111; 3'h7: CHAR_ROM = 8'b10111111; default: CHAR_ROM = 8'hxx; endcase
			4'h8: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b11000111; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10000011; 3'h4: CHAR_ROM = 8'b11000001; 3'h5: CHAR_ROM = 8'b10000111; 3'h6: CHAR_ROM = 8'b10000001; 3'h7: CHAR_ROM = 8'b10111111; default: CHAR_ROM = 8'hxx; endcase
			default: CHAR_ROM = 8'hxx; endcase
		3'b010: case (ROW_ADDRESS)
			4'h0,`CHAR_HEIGHT: CHAR_ROM = 8'hFF;
			4'h1: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11100001; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b10000001; 3'h3: CHAR_ROM = 8'b10000001; 3'h4: CHAR_ROM = 8'b10111101; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111001; default: CHAR_ROM = 8'hxx; endcase
			4'h2: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11011101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11111011; 3'h4: CHAR_ROM = 8'b10111011; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10011001; 3'h7: CHAR_ROM = 8'b10011101; default: CHAR_ROM = 8'hxx; endcase
			4'h3: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111111; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11111011; 3'h4: CHAR_ROM = 8'b10110111; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10100101; 3'h7: CHAR_ROM = 8'b10101101; default: CHAR_ROM = 8'hxx; endcase
			4'h4: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111111; 3'h1: CHAR_ROM = 8'b10000001; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11111011; 3'h4: CHAR_ROM = 8'b10101111; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10100101; 3'h7: CHAR_ROM = 8'b10101101; default: CHAR_ROM = 8'hxx; endcase
			4'h5: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10110001; 3'h1: CHAR_ROM = 8'b10000001; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11111011; 3'h4: CHAR_ROM = 8'b10011111; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10110101; default: CHAR_ROM = 8'hxx; endcase
			4'h6: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b10111011; 3'h4: CHAR_ROM = 8'b10101111; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10110101; default: CHAR_ROM = 8'hxx; endcase
			4'h7: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b10111011; 3'h4: CHAR_ROM = 8'b10110111; 3'h5: CHAR_ROM = 8'b11111101; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111001; default: CHAR_ROM = 8'hxx; endcase
			4'h8: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b10000001; 3'h3: CHAR_ROM = 8'b10000111; 3'h4: CHAR_ROM = 8'b10111001; 3'h5: CHAR_ROM = 8'b10000001; 3'h6: CHAR_ROM = 8'b10011001; 3'h7: CHAR_ROM = 8'b10011101; default: CHAR_ROM = 8'hxx; endcase
			default: CHAR_ROM = 8'hxx; endcase
		3'b011: case (ROW_ADDRESS)
			4'h0,`CHAR_HEIGHT: CHAR_ROM = 8'hFF;
			4'h1: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b10000011; 3'h2: CHAR_ROM = 8'b11000011; 3'h3: CHAR_ROM = 8'b10000011; 3'h4: CHAR_ROM = 8'b11000011; 3'h5: CHAR_ROM = 8'b10000001; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111101; default: CHAR_ROM = 8'hxx; endcase
			4'h2: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b10111101; 3'h5: CHAR_ROM = 8'b11100111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111101; default: CHAR_ROM = 8'hxx; endcase
			4'h3: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b10111111; 3'h5: CHAR_ROM = 8'b11100111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111101; default: CHAR_ROM = 8'hxx; endcase
			4'h4: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10000011; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10000011; 3'h4: CHAR_ROM = 8'b11001111; 3'h5: CHAR_ROM = 8'b11100111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111101; default: CHAR_ROM = 8'hxx; endcase
			4'h5: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111111; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10001111; 3'h4: CHAR_ROM = 8'b11110011; 3'h5: CHAR_ROM = 8'b11100111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111101; default: CHAR_ROM = 8'hxx; endcase
			4'h6: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111111; 3'h2: CHAR_ROM = 8'b10110101; 3'h3: CHAR_ROM = 8'b10110111; 3'h4: CHAR_ROM = 8'b11111101; 3'h5: CHAR_ROM = 8'b11100111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b11011011; default: CHAR_ROM = 8'hxx; endcase
			4'h7: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111111; 3'h2: CHAR_ROM = 8'b10111001; 3'h3: CHAR_ROM = 8'b10111011; 3'h4: CHAR_ROM = 8'b10111101; 3'h5: CHAR_ROM = 8'b11100111; 3'h6: CHAR_ROM = 8'b10011001; 3'h7: CHAR_ROM = 8'b11011011; default: CHAR_ROM = 8'hxx; endcase
			4'h8: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11000011; 3'h1: CHAR_ROM = 8'b10111111; 3'h2: CHAR_ROM = 8'b11000101; 3'h3: CHAR_ROM = 8'b10111101; 3'h4: CHAR_ROM = 8'b11000011; 3'h5: CHAR_ROM = 8'b11100111; 3'h6: CHAR_ROM = 8'b11000011; 3'h7: CHAR_ROM = 8'b11100111; default: CHAR_ROM = 8'hxx; endcase
			default: CHAR_ROM = 8'hxx; endcase
		3'b100: case (ROW_ADDRESS)
			4'h0,`CHAR_HEIGHT: CHAR_ROM = 8'hFF;
			4'h1: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10011001; 3'h1: CHAR_ROM = 8'b10011001; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10000001; default: CHAR_ROM = 8'hxx; endcase
			4'h2: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b10111101; default: CHAR_ROM = 8'hxx; endcase
			4'h3: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b10111101; 3'h3: CHAR_ROM = 8'b11111101; default: CHAR_ROM = 8'hxx; endcase
			4'h4: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b11000011; 3'h2: CHAR_ROM = 8'b11011011; 3'h3: CHAR_ROM = 8'b11111011; default: CHAR_ROM = 8'hxx; endcase
			4'h5: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10100101; 3'h1: CHAR_ROM = 8'b11000011; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11110111; default: CHAR_ROM = 8'hxx; endcase
			4'h6: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10100101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11101111; default: CHAR_ROM = 8'hxx; endcase
			4'h7: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10011001; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11011101; default: CHAR_ROM = 8'hxx; endcase
			4'h8: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10011001; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b10000001; default: CHAR_ROM = 8'hxx; endcase
			default: CHAR_ROM = 8'hxx; endcase
		3'b101,
		3'b110,
		3'b111: CHAR_ROM = 8'hFF;
		default: CHAR_ROM = 8'hxx;
		endcase

endmodule
