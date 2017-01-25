module Reg_Bank (
	input clk,
	input RESET_pin,
	input [7:0] SB,

	input ACC_en,
	input iX_en,
	input iY_en,
	input SP_en,

	output reg [7:0] Acc,
	output reg [7:0] iX,
	output reg [7:0] iY,
	output reg [7:0] SP
	);

// Data register have been reset to aid correct simulation
always @ (posedge clk) begin
	if(~RESET_pin) begin
		SP  <= 8'h00;
		Acc <= 8'h00;
		iX  <= 8'h00;
		iY  <= 8'h00;
	end else begin
		if(SP_en)  SP  <= SB;
		if(ACC_en) Acc <= SB;
		if(iX_en)  iX  <= SB;
		if(iY_en)  iY  <= SB;
	end
end

endmodule // Reg_Bank
