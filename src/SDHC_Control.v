`define NO_CARD		7'h00
`define SD_1msW		7'h01
`define SD_74DW		7'h02
`define SD_INIT		7'h03

`define SD_CMD0 	7'h04
`define SD_ARG01 	7'h05
`define SD_ARG02 	7'h06
`define SD_ARG03 	7'h07
`define SD_ARG04 	7'h08
`define SD_CRC0 	7'h09
`define SD_WAIT0 	7'h0A
`define SD_CHKR0 	7'h0B

`define SD_CMD8 	7'h14
`define SD_ARG81 	7'h15
`define SD_ARG82 	7'h16
`define SD_ARG83 	7'h17
`define SD_ARG84 	7'h18
`define SD_CRC8 	7'h19
`define SD_WAIT8 	7'h1A
`define SD_CHKR80	7'h1B
`define SD_CHKR81 	7'h1C
`define SD_CHKR82 	7'h1D
`define SD_CHKR83 	7'h1E
`define SD_CHKR84 	7'h1F

`define SD_CMD55 	7'h24
`define SD_ARG551 	7'h25
`define SD_ARG552 	7'h26
`define SD_ARG553 	7'h27
`define SD_ARG554 	7'h28
`define SD_CRC55 	7'h29
`define SD_WAIT55 	7'h2A
`define SD_CHKR55 	7'h2B

`define SD_ACMD41 	7'h34
`define SD_AARG411 	7'h35
`define SD_AARG412 	7'h36
`define SD_AARG413 	7'h37
`define SD_AARG414 	7'h38
`define SD_ACRC41 	7'h39
`define SD_AWAIT41 	7'h3A
`define SD_CHKR41 	7'h3B

`define SD_FAIL		7'h30
`define SD_READY 	7'h40


module SDHC_Control (
	input clk,
	input SD_CD,
	input MOSI,
	input SCK,

	inout [3:0] SD_DAT,

	output SD_RESET,
	output SD_CMD,
	output SD_SCK,
	output MISO);

	wire EARLY;
	wire READY;
	wire iSCK;
	wire iCMD;
	wire clk_en;

	reg [7:0] SR_IN;
	reg LOAD;
	reg DONE;
	reg VALID;
	reg OUT_OF_TIME;

/***************************************************************************************/
// Shift control

	reg [7:0] SR;
	reg [3:0] SR_COUNT;
	reg SR_ACTIVE;
	reg SNDCLK;

	wire pos_iSCK;
	Edge_Trigger #(1) POS_SCK(.clk(clk),.IN(iSCK),.En(1'b1),.EDGE(pos_iSCK));

	always @ ( posedge clk )
		if(SR_ACTIVE)
			SNDCLK <= clk_en? ~SNDCLK : SNDCLK;
		else
			SNDCLK <= 1'b1;

	always @ ( posedge clk )
		if(SD_CD)
			SR_ACTIVE <= 1'b0;
		else if(~SR_ACTIVE)
			SR_ACTIVE <= LOAD;
		else
			SR_ACTIVE <= |SR_COUNT;

	always @ ( posedge clk )
		if(LOAD) begin
			SR_COUNT <= 4'h8;
			SR <= SR_IN;
		end else if(pos_iSCK & SR_ACTIVE) begin
			SR_COUNT <= SR_COUNT + 4'hF;
			SR <= {SR[6:0],SD_DAT[0]};
		end

/****************************************************************************************/
	reg [7:0] clkCOUNT;
	always @ ( posedge clk ) clkCOUNT <= clkCOUNT + 1;

//	INIT Phase

	reg [8:0] SD_INIT_COUNT;
	always @ ( posedge clk )
		if(SD_STATE == `NO_CARD)
			SD_INIT_COUNT <= 9'h1FF;
		else if(pos_iSCK)
			SD_INIT_COUNT <= SD_INIT_COUNT + 9'h1FF;

	wire COUNTER0 = ~|SD_INIT_COUNT;
/****************************************************************************************/

	reg [6:0] SD_STATE;
	always @ ( posedge clk ) begin
		if(SD_CD)
			SD_STATE <= `NO_CARD;
		else if(clk_en & DONE)
			case (SD_STATE)
				`NO_CARD: SD_STATE <= `SD_1msW;
				`SD_1msW: SD_STATE <= `SD_74DW;
				`SD_74DW: SD_STATE <= `SD_INIT;
				`SD_INIT: SD_STATE <= `SD_CMD0;

				`SD_CMD0:	SD_STATE <= `SD_ARG01;
				`SD_ARG01:	SD_STATE <= `SD_ARG02;
				`SD_ARG02:	SD_STATE <= `SD_ARG03;
				`SD_ARG03:	SD_STATE <= `SD_ARG04;
				`SD_ARG04:	SD_STATE <= `SD_CRC0;
				`SD_CRC0:	SD_STATE <= `SD_WAIT0;
				`SD_WAIT0:	SD_STATE <= `SD_CHKR0;
				`SD_CHKR0:	SD_STATE <= VALID? `SD_CMD8 : `SD_FAIL;

				`SD_CMD8:	SD_STATE <= `SD_ARG81;
				`SD_ARG81:	SD_STATE <= `SD_ARG82;
				`SD_ARG82:	SD_STATE <= `SD_ARG83;
				`SD_ARG83:	SD_STATE <= `SD_ARG84;
				`SD_ARG84:	SD_STATE <= `SD_CRC8;
				`SD_CRC8:	SD_STATE <= `SD_WAIT8;
				`SD_WAIT8:	SD_STATE <= `SD_CHKR80;
				`SD_CHKR80: SD_STATE <= VALID? `SD_CHKR81 : `SD_FAIL;
				`SD_CHKR81:	SD_STATE <= VALID? `SD_CHKR82 : `SD_FAIL;
				`SD_CHKR82: SD_STATE <= VALID? `SD_CHKR83 : `SD_FAIL;
				`SD_CHKR83:	SD_STATE <= VALID? `SD_CHKR84 : `SD_FAIL;
				`SD_CHKR84: SD_STATE <= VALID? `SD_CMD55  : `SD_FAIL;

				`SD_CMD55:	SD_STATE <= `SD_ARG551;
				`SD_ARG551: SD_STATE <= `SD_ARG552;
				`SD_ARG552: SD_STATE <= `SD_ARG553;
				`SD_ARG553: SD_STATE <= `SD_ARG554;
				`SD_ARG554: SD_STATE <= `SD_CRC55;
				`SD_CRC55:	SD_STATE <= `SD_WAIT55;
				`SD_WAIT55: SD_STATE <= `SD_CHKR55;
				`SD_CHKR55: SD_STATE <= VALID? `SD_ACMD41 : OUT_OF_TIME? `SD_FAIL : `SD_CMD55;

				`SD_ACMD41: SD_STATE <= `SD_AARG411;
				`SD_AARG411:SD_STATE <= `SD_AARG412;
				`SD_AARG412:SD_STATE <= `SD_AARG413;
				`SD_AARG413:SD_STATE <= `SD_AARG414;
				`SD_AARG414:SD_STATE <= `SD_ACRC41;
				`SD_ACRC41: SD_STATE <= `SD_AWAIT41;
				`SD_AWAIT41:SD_STATE <= `SD_CHKR41;
				`SD_CHKR41: SD_STATE <= VALID? `SD_READY : OUT_OF_TIME? `SD_FAIL : `SD_CMD55;
			endcase
	end


	always @ ( * ) begin
		casex (SD_STATE)	// DONE
			`NO_CARD:		DONE = 1;
			`SD_1msW,
			`SD_74DW:		DONE = COUNTER0;
			`SD_INIT:		DONE = pos_iSCK;
			7'bxxx_1010:	DONE = SD_DAT[0];
			7'bxxx_1011,
			7'bxxx_100x,
			7'bxxx_x1xx:	DONE = SR_DONE;
			default:		DONE = 0;
		endcase
		
		casex (SD_STATE)	// VALID
			`SD_CHKR0:		VALID = SR == 8'h01;
			`SD_CHKR81:		VALID = SR == 8'h00;
			`SD_CHKR82:		VALID = SR == 8'h00;
			`SD_CHKR83:		VALID = SR == 8'h01;
			`SD_CHKR84:		VALID = SR == 8'hAA;
			7'bxxx_1011:	VALID = SR == 8'h00;
			default:		VALID = 0;
		endcase
	end

/****************************************************************************************/

	assign SD_RESET = 1'b0;
	assign SD_CMD	= READY? MOSI : iCMD;
	assign SD_SCK	= READY? SCK  : iSCK;
	assign MISO		= SD_DAT[0];
	assign SD_DAT[3:1] = EARLY? 3'h7 : 3'h0;

	assign clk_en = ~|clkCOUNT[2:0];
	assign iSCK  = EARLY? clkCOUNT[7] : SNDCLK;
	assign iCMD  = EARLY? 1'b1 : CMD_SR[7];
	
	assign EARLY = 0;
	assign READY = 1;//SD_STATE == `SD_READY;

/****************************************************************************************/

	`ifdef SIMULATION
		initial begin
			clkCOUNT = $urandom_range(255,0);
		end
	`endif

endmodule
