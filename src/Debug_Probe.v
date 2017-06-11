module Debug_Probe (
	input CLK,
	input DEBUGen,
	input UPDATE,
	input SELen,

	input [15:0] VALUE,
	input [23:0] TAG,
	input LINE,
	input NEXT_CHAR,
	input [1:0]  BUTTON,

	output reg [3:0] SEL,
	output [5:0] CHAR_ADDR
	);

	`ifdef SIMULATION
		initial begin
		SEL = 0;
		end
	`endif


	wire BUTTON_NEXT = BUTTON[0];
	wire BUTTON_PREV = BUTTON[1];

	always @ (posedge CLK)
		if(SELen)
			if(BUTTON_NEXT)
				SEL <= SEL + 1;
			else if(BUTTON_PREV)
				SEL <= SEL + 4'hF;

	reg [23:0] TAG_SR;
	reg [15:0] VALUE_SR;

	always @ ( posedge CLK ) begin
		if(UPDATE) begin
			TAG_SR   <= TAG;
			VALUE_SR <= VALUE;
		end else if(DEBUGen & NEXT_CHAR) begin
			TAG_SR   <= {TAG_SR[17:0],TAG_SR[23:18]};
			VALUE_SR <= {VALUE_SR[11:0],VALUE_SR[15:12]};
		end
	end

	assign CHAR_ADDR = LINE? {2'b00,VALUE_SR[15:12]} : TAG_SR[23:18];

endmodule // Debug_Tool
