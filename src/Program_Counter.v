module Program_Counter (
	input [7:0] ADB_lo,
	input [7:0] ADB_hi,

	input clk,
	input nRES,
	input PC_en,
	input PC_inc,

	output reg [7:0] PCL,
	output reg [7:0] PCH);

always @ (posedge clk) begin
	if(~nRES) begin
		PCL <= 8'h00;
		PCH <= 8'h00;
	end else if(PC_en) begin
		PCL <= ADB_lo + PC_inc;
		PCH <= ADB_hi + (&PCL? PC_inc : 0);
	end
end

endmodule // Program_Counter
