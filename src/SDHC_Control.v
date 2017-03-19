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
	
/***************************************************************************************/
// Shift control

	reg [7:0] SR_IN;
	reg LOAD;
	
	reg [7:0] SR;
	reg [3:0] SR_COUNT;
	reg SR_ACTIVE;
	reg SNDCLK;
	
	wire pos_iSCK;
	Edge_Trigger #(1) POS_SCK(.clk(clk),.IN(iSCK),.En(1'b1),.EDGE(pos_iSCK));
	
	always @ ( posedge clk )
		if(SR_ACTIVE & ~|clkCOUNT[2:0])
			SNDCLK <= ~SNDCLK;
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

/***************************************************************************************/
	assign EARLY = SD_STATE == `SD_INIT || SD_STATE == `NO_CARD;
	
	wire clk_en;
	reg [7:0] clkCOUNT;
	
	assign clk_en = ~|clkCOUNT[2:0];
	assign iSCK = EARLY? clkCOUNT[7] : SNDCLK;
	always @ ( posedge clk ) clkCOUNT <= clkCOUNT + 1;
		

	reg [2:0] SD_STATE;
	always @ ( posedge clk )
		if(clk_en)
			if(SD_CD) SD_STATE <= `NO_CARD;
			else case(SD_STATE)
				`NO_CARD:	SD_STATE <= `SD_INIT;
				`SD_INIT:	SD_STATE <= INIT_DONE?  `SD_SRST : `SD_INIT;
				`SD_SRST:	SD_STATE <= SRST_DONE?  `SD_IDLE : `SD_SRST;
				`SD_IDLE:	SD_STATE <= SPI_SET?	`SD_SPI  : `SD_IDLE;
			endcase
	
	assign READY = SD_STATE == `SD_SPI;
	

/***************************************************************************************/
//	INIT Phase
	
	reg [8:0] SD_INIT_COUNT;
	wire INIT_DONE = ~|SD_INIT_COUNT;
	always @ ( posedge clk )
		if(SD_STATE == `NO_CARD)
			SD_INIT_COUNT <= 9'h1FF;
		else if(pos_iSCK)
			SD_INIT_COUNT <= SD_INIT_COUNT + 9'h1FF;
				
//	SRST Phase
				
	reg [1:0] RST_PHASE;
	reg [7:0] CMD_SR;

	wire SRST_DONE;
	assign iCMD = CMD_SR[7];

	always @ ( posedge clk )
		if(clk_en)
			if(SD_STATE != `SD_SRST)
				RST_PHASE <= 2'b01
			if(SD_STATE == `SD_SRST)

/*********************************************************************************************/
	
	assign SD_RESET = 1'b0;
	assign SD_CMD	= READY? MOSI : iCMD;
	assign SD_SCK	= READY? SCK  : iSCK;
	assign MISO		= SD_DAT[0];
	assign SD_DAT[3:1] = EARLY? 3'h7 : 3'h0
	
/*********************************************************************************************/

	`ifdef SIMULATION
		initial begin
			clkCOUNT = $urandom_range(255,0);
		end
	`endif
	
endmodule

