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


always @ (posedge clk) begin
	if(~RESET_pin) SP <= 8'h00;
	else if(SP_en) SP <= SB;

	if(ACC_en) Acc <= SB;
	if(iX_en)  iX  <= SB;
	if(iY_en)  iY  <= SB;
end

endmodule // Reg_Bank
