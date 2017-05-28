`include "TOP.vh"

module CRTC_test();

	event START_LOG;
	initial begin
		@(START_LOG);
		$dumpvars(0, CRTC_test);
	end
	
	// input
	reg CLK100MHZ;
	reg nRESET;
	reg CRTC_en;
	reg PROC_en;
	reg nCS_CRTC;
	reg RnW;
	reg A0;
	
	// inout
	wire [7:0] pDATABUS;
	
	// output
	wire HSYNC;
	wire VSYNC;
	wire DISEN;
	wire CURSOR;
	wire [13:0] FRAMESTORE_ADR;
	wire  [4:0] ROW_ADDRESS;

	CRTC6845 crtc(
	.CLK(CLK100MHZ),
	.nRESET(nRESET),
	.CRTC_en(CRTC_en),
	.PROC_en(PROC_en),
	.nCS_CRTC(nCS_CRTC),
	.RnW(RnW),
	.A0(A0),
	
	.pDATABUS(pDATABUS),

	.HSYNC(HSYNC),
	.VSYNC(VSYNC),
	.DISEN(DISEN),
	.CURSOR(CURSOR),
	.FRAMESTORE_ADR(FRAMESTORE_ADR),
	.ROW_ADDRESS(ROW_ADDRESS)
	);

	assign pDATABUS = ~RnW? pDATABUS_out : 8'hzz;

	reg [7:0] pDATABUS_out;
	reg [3:0] CRTC_COUNT;
	initial CLK100MHZ  = 0;
	initial CRTC_COUNT = 0;
	
	always #(`CLKPERIOD/2) CLK100MHZ = ~CLK100MHZ;
	always @(posedge CLK100MHZ) CRTC_COUNT <= CRTC_COUNT + 1;
	always @(posedge CLK100MHZ) CRTC_en <= CRTC_COUNT==4'h7;
	always @(posedge CLK100MHZ) PROC_en <= CRTC_COUNT==4'hF;
/******************************************************************************/

	task Set_Register;
		input [4:0] adr;
		input [7:0] value;
		begin
			while (~PROC_en) @(posedge CLK100MHZ);
			A0  <= 0;
			pDATABUS_out <= adr;
			@(posedge CLK100MHZ);
			while (~PROC_en) @(posedge CLK100MHZ);
			A0  <= 1;
			pDATABUS_out <= value;
			@(posedge CLK100MHZ);
			while (~PROC_en) @(posedge CLK100MHZ);
		end
	endtask


/******************************************************************************/

	initial begin
		nRESET <= 0;
		nCS_CRTC <= 0;
		RnW <= 0;
		repeat (10) @(posedge CLK100MHZ);
		// Test modes 0 to 2
		Set_Register(0,8'h7F);
		Set_Register(1,8'h50);
		Set_Register(2,8'h62);
		Set_Register(3,8'h28);
		Set_Register(4,8'h26);
		Set_Register(5,8'h00);
		Set_Register(6,8'h20);
		Set_Register(7,8'h22);
		Set_Register(8,8'h01);
		Set_Register(9,8'h07);
		Set_Register(10,8'h67);
		Set_Register(11,8'h08);
		Set_Register(12,8'h00);
		Set_Register(13,8'h00);
		Set_Register(14,8'h02);
		Set_Register(15,8'h00);
		RnW <= 1;
		nRESET <= 1;
		repeat (30) @(posedge VSYNC);
		-> START_LOG;
        repeat (5) @(posedge VSYNC);
		// Test mode 3
		RnW <= 0;
		Set_Register(4,8'h1E);
		Set_Register(5,8'h02);
		Set_Register(6,8'h19);
		Set_Register(7,8'h1B);
		Set_Register(9,8'h09);
		Set_Register(10,8'h67);
		Set_Register(11,8'h09);
		RnW <= 1;
		repeat (5) @(posedge VSYNC);
		// Test mode 7
		RnW <= 0;
		Set_Register(0,8'h3F);
		Set_Register(1,8'h28);
		Set_Register(2,8'h33);
		Set_Register(3,8'h24);
		Set_Register(4,8'h1E);
		Set_Register(5,8'h02);
		Set_Register(6,8'h19);
		Set_Register(7,8'h1B);
		Set_Register(8,8'h93);
		Set_Register(9,8'h12);
		Set_Register(10,8'h72);
		Set_Register(11,8'h13);
		RnW <= 1;
		repeat (5) @(posedge VSYNC);
		$stop;
		$finish;
	end
	
	integer SCREEN_COUNT = 0;
	always @(posedge VSYNC) begin
		SCREEN_COUNT = SCREEN_COUNT + 1;
		$display("SCREEN No. %d", SCREEN_COUNT);
	end
	

endmodule
