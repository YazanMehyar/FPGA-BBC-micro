module ADC (
	input		CLK,
	input		CLK_en,
	input		nRESET,
	input		nCS,
	input		RnW,
	input [1:0] A10,
	input [3:0]	CH,
	input [1:0]	FIRE,
	output reg  nEOC,
	output[1:0]	I,
	inout [7:0] DATA
);

	reg [3:0] STATUS;
	reg [7:0] HI_BYTE;
	reg [3:0] LO_BYTE;
	reg		  IDLE;
	
	wire [1:0] R;
	wire [3:0] FS;
	
	wire STATUS_WRITE = ~|{nCS,RnW,A10};

	reg [7:0] DATA_out;
	assign DATA = (~nCS&nRESET&RnW)? DATA_out : 8'hzz;
	
	always @ (*) casex (A10)
		2'b00: DATA_out = {nEOC,~nEOC,HI_BYTE[7:6],STATUS};
		2'b01: DATA_out = HI_BYTE;
		2'b1x: DATA_out = {LO_BYTE, 4'h0};
	endcase
	
	always @ (posedge CLK or negedge nRESET)
		if(~nRESET) 
			IDLE <= 1;
		else if(STATUS_WRITE)
			IDLE <= 0;
	
	always @ (posedge CLK) if(CLK_en) begin
		if(STATUS_WRITE) STATUS <= DATA[3:0];
	end
		
	always @ (posedge CLK) begin
		if(STATUS_WRITE|IDLE) 
			nEOC <= 1;
		else if(CLK_en&nEOC) casex (STATUS[1:0])
			2'bx0: begin nEOC <= ~R[0]; {HI_BYTE,LO_BYTE} <= V1; end
			2'bx1: begin nEOC <= ~R[1]; {HI_BYTE,LO_BYTE} <= V2; end
		endcase
	end
	
	reg [11:0] V1,V2;
	always @ (*) begin
		casex(FS[1:0])
		2'b01: V1 = 12'h000;
		2'b00: V1 = 12'h900;
		2'b10: V1 = 12'hFFF;
		2'b11: V1 = 12'h900;
		endcase
		
		casex(FS[3:2])
		2'b01: V2 = 12'h000;
		2'b00: V2 = 12'h900;
		2'b10: V2 = 12'hFFF;
		2'b11: V2 = 12'h900;
		endcase
	end
/**************************************************************************************************/
	
	reg [9:0] counter = 0;
	always @ (posedge CLK) if(CLK_en) counter <= counter + 1;
	wire Filter_en = ~|counter;
	
	wire nFRESET = ~|{STATUS_WRITE,IDLE} & nRESET;
	
	// Channel Filters
	Filter #(
		.DEBOUNCE_COUNT(4),
		.PRESET_VALUE(1),
		.INPUT_WIDTH(2)
	) f0 (
		.CLK(CLK),
		.CLK_en(Filter_en),
		.READY_en(CLK_en),
		.nRESET(nFRESET),
		.SIGNAL(CH[1:0]),
		.FILTERED_SIGNAL(FS[1:0]),
		.READY(R[0])
	);
	
	Filter #(
		.DEBOUNCE_COUNT(4),
		.PRESET_VALUE(1),
		.INPUT_WIDTH(2)
	) f1 (
		.CLK(CLK),
		.CLK_en(Filter_en),
		.READY_en(CLK_en),
		.nRESET(nFRESET),
		.SIGNAL(CH[3:2]),
		.FILTERED_SIGNAL(FS[3:2]),
		.READY(R[1])
	);
	
	Filter #(
		.DEBOUNCE_COUNT(4),
		.PRESET_VALUE(1)
	) fb0 (
		.CLK(CLK),
		.CLK_en(Filter_en),
		.READY_en(1'bx),
		.nRESET(nRESET),
		.SIGNAL(FIRE[0]),
		.FILTERED_SIGNAL(I[0])
	);
	
	Filter #(
		.DEBOUNCE_COUNT(4),
		.PRESET_VALUE(1)
	) fb1 (
		.CLK(CLK),
		.CLK_en(Filter_en),
		.READY_en(1'bx),
		.nRESET(nRESET),
		.SIGNAL(FIRE[1]),
		.FILTERED_SIGNAL(I[1])
	);
	

	
endmodule
