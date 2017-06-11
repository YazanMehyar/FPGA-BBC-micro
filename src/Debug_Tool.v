module Debug_Tool(
	input CLK,
	input NEWLINE,
	input ENABLE,
	input BUTTON_EN,

	input [23:0] TAG1,
	input [23:0] TAG2,
	input [23:0] TAG3,
	input [23:0] TAG4,
	input [23:0] TAGB,
	input [15:0] VAL1,
	input [15:0] VAL2,
	input [15:0] VAL3,
	input [15:0] VAL4,
	input [15:0] VALB,
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

	reg [5:0] CHAR_ADDR;
	reg [3:0] PIXEL_COUNT;
	reg [3:0] ROW_ADDRESS;
	reg [2:0] LINE;
	reg [3:0] Dsel;
	reg [5:0] Den;
	reg [4:0] PROBEen;
	reg HIGHLIGHT;

	wire NEXT_CHAR;
	wire BUTTON_NEXT;
	wire BUTTON_PREV;
	wire UPDATE;

	wire [5:0] CHARADR1;
	wire [5:0] CHARADR2;
	wire [5:0] CHARADR3;
	wire [5:0] CHARADR4;
	wire [5:0] CHARADRB;

	`ifdef SIMULATION
		initial begin
			Den  = 0;
			Dsel = 0;
			ROW_ADDRESS = 0;
			PIXEL_COUNT = 0;
		end
	`endif

	assign BUTTON_NEXT = TOOL_B[0];
	assign BUTTON_PREV = TOOL_B[1];

	always @ ( posedge CLK )
		if(~|PIXEL_COUNT|NEWLINE)
			PIXEL_COUNT <= `CHAR_WIDTH;
		else if(ENABLE)
			PIXEL_COUNT <= PIXEL_COUNT - 1;

	always @ ( posedge CLK ) if(BUTTON_EN) begin
		if(~|Dsel)
			Dsel <= 4'h1;
		else if(BUTTON_NEXT)
			Dsel <= {Dsel[2:0],Dsel[3]};
		else if(BUTTON_PREV)
			Dsel <= {Dsel[0],Dsel[3:1]};
	end

	always @ (posedge CLK)
		if(~ENABLE)
			ROW_ADDRESS <= 0;
		else if(NEWLINE)
			if(ROW_ADDRESS != `CHAR_HEIGHT)
				ROW_ADDRESS <= ROW_ADDRESS + 1;
			else
				ROW_ADDRESS <= 0;

	always @ (posedge CLK) begin
		if(~ENABLE)
			LINE <= 3'h4;
		else if(~LINE[0] & NEWLINE & (ROW_ADDRESS == `CHAR_HEIGHT))
			LINE <= LINE >> 1;
	end

	always @ (posedge CLK)
		if(NEWLINE)
			Den <= 0;
		else if(NEXT_CHAR & ~&Den)
			Den <= Den + 1;

	always @ (posedge CLK)
		if(NEXT_CHAR) HIGHLIGHT <= |(Dsel&PROBEen);

	always @ ( * )
		if(~Den[2]) case (Den[5:3])
			3'b000: begin CHAR_ADDR = CHARADR1; PROBEen = 5'h01; end
			3'b001: begin CHAR_ADDR = CHARADR2; PROBEen = 5'h02; end
			3'b010: begin CHAR_ADDR = CHARADR3; PROBEen = 5'h04; end
			3'b011: begin CHAR_ADDR = CHARADR4; PROBEen = 5'h08; end
			3'b100: begin CHAR_ADDR = CHARADRB; PROBEen = 5'h10; end
			default: begin CHAR_ADDR = 6'h38; PROBEen = 4'h0; end
		endcase else begin CHAR_ADDR = 6'h38; PROBEen = 4'h0; end


/****************************************************************************************/
	assign NEXT_CHAR = ~|PIXEL_COUNT & ENABLE;
	assign PIXEL_OUT = ENABLE&~LINE[0]? HIGHLIGHT ~^ CHAR_SR[`CHAR_WIDTH] : 1'b0;
	assign UPDATE = ~ENABLE;

	Debug_Probe dp1(
		.CLK(CLK),
		.DEBUGen(PROBEen[0]),
		.SELen(Dsel[0]&BUTTON_EN),
		.UPDATE(UPDATE),
		.VALUE(VAL1),
		.TAG(TAG1),
		.LINE(LINE[1]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(PROBE_B),
		.SEL(SEL1),
		.CHAR_ADDR(CHARADR1)
	);

	Debug_Probe dp2(
		.CLK(CLK),
		.DEBUGen(PROBEen[1]),
		.SELen(Dsel[1]&BUTTON_EN),
		.UPDATE(UPDATE),
		.VALUE(VAL2),
		.TAG(TAG2),
		.LINE(LINE[1]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(PROBE_B),
		.SEL(SEL2),
		.CHAR_ADDR(CHARADR2)
	);

	Debug_Probe dp3(
		.CLK(CLK),
		.DEBUGen(PROBEen[2]),
		.SELen(Dsel[2]&BUTTON_EN),
		.UPDATE(UPDATE),
		.VALUE(VAL3),
		.TAG(TAG3),
		.LINE(LINE[1]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(PROBE_B),
		.SEL(SEL3),
		.CHAR_ADDR(CHARADR3)
	);

	Debug_Probe dp4(
		.CLK(CLK),
		.DEBUGen(PROBEen[3]),
		.SELen(Dsel[3]&BUTTON_EN),
		.UPDATE(UPDATE),
		.VALUE(VAL4),
		.TAG(TAG4),
		.LINE(LINE[1]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(PROBE_B),
		.SEL(SEL4),
		.CHAR_ADDR(CHARADR4)
	);

	Debug_Probe dp_break(
		.CLK(CLK),
		.DEBUGen(PROBEen[4]),
		.SELen(1'b0),
		.UPDATE(UPDATE),
		.VALUE(VALB),
		.TAG(TAGB),
		.LINE(LINE[1]),
		.NEXT_CHAR(NEXT_CHAR),
		.BUTTON(2'b00),
		.CHAR_ADDR(CHARADRB)
	);

/****************************************************************************************/

	// Char ROM as big case statement
	reg [`CHAR_WIDTH:0] CHAR_SR;
	reg [`CHAR_WIDTH:0] CHAR_ROM;

	always @ (posedge CLK)
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
			4'h1: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11100001; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b10000001; 3'h3: CHAR_ROM = 8'b10000001; 3'h4: CHAR_ROM = 8'b10111101; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111001; default: CHAR_ROM = 8'hxx; endcase
			4'h2: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b11011101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11111011; 3'h4: CHAR_ROM = 8'b10111011; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10011001; 3'h7: CHAR_ROM = 8'b10011101; default: CHAR_ROM = 8'hxx; endcase
			4'h3: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111111; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11111011; 3'h4: CHAR_ROM = 8'b10110111; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10100101; 3'h7: CHAR_ROM = 8'b10101101; default: CHAR_ROM = 8'hxx; endcase
			4'h4: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111111; 3'h1: CHAR_ROM = 8'b10000001; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11111011; 3'h4: CHAR_ROM = 8'b10101111; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10100101; 3'h7: CHAR_ROM = 8'b10101101; default: CHAR_ROM = 8'hxx; endcase
			4'h5: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10110001; 3'h1: CHAR_ROM = 8'b10000001; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b11111011; 3'h4: CHAR_ROM = 8'b10011111; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10110101; default: CHAR_ROM = 8'hxx; endcase
			4'h6: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b10111011; 3'h4: CHAR_ROM = 8'b10101111; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10110101; default: CHAR_ROM = 8'hxx; endcase
			4'h7: case (CHAR_ADDR[2:0]) 3'h0: CHAR_ROM = 8'b10111101; 3'h1: CHAR_ROM = 8'b10111101; 3'h2: CHAR_ROM = 8'b11100111; 3'h3: CHAR_ROM = 8'b10111011; 3'h4: CHAR_ROM = 8'b10110111; 3'h5: CHAR_ROM = 8'b10111111; 3'h6: CHAR_ROM = 8'b10111101; 3'h7: CHAR_ROM = 8'b10111001; default: CHAR_ROM = 8'hxx; endcase
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
