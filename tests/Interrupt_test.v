`include "TOP.vh"
module Interrupt_test ();

	// input
	reg clk;
	wire clk_en;
	reg nNMI;
	reg nIRQ;
	reg nSO;
	reg nRESET;
	reg nRESET_req;
	reg T0;
	reg NEXT_T;
	reg I_mask;

	// output
	wire nNMI_req;
	wire nNMI_T0;
	wire nIRQ_req;
	wire nIRQ_T0;
	wire SO_req;

	MOS6502_Interrupt i(
		.clk(clk),
		.clk_en(clk_en),
		.nNMI(nNMI),
		.nIRQ(nIRQ),
		.nSO(nSO),
		.nRESET(nRESET&nRESET_req),
		.T0(T0),
		.NEXT_T(NEXT_T),
		.I_mask(I_mask),

		.nNMI_req(nNMI_req),
		.nNMI_T0(nNMI_T0),
		.nIRQ_req(nIRQ_req),
		.nIRQ_T0(nIRQ_T0),
		.SO_req(SO_req)
	);

	reg [3:0] clk_count;
	
/**************************************************************************************************/
	
	initial begin
		$dumpvars(0,Interrupt_test);
		clk = 0;
		clk_count = 0;
		T0 = 0;
	end
	
	always #(`CLKPERIOD/2) clk = ~clk;

	always @ (posedge clk) begin
		clk_count <= clk_count + 1;

		if(clk_en)		
			T0 <= $urandom_range(4,0)%5 == 0;
		
		if(~nRESET)		nRESET_req	<= 1'b0;
		else if(clk_en) nRESET_req	<= (nRESET_req | T0);
	end

	assign clk_en = &clk_count;	

	initial begin
	I_mask  <= 0;
	nIRQ <= 1;
	nNMI <= 1;
	nSO  <= 1;

	NEXT_T <= 0;
	nRESET <= 0; // active low reset
	repeat (3) @(posedge clk);
	nRESET <= 1;

	// Test IRQ
	repeat (4) @(posedge clk_en);
	nIRQ <= 0;
	repeat (4) @(posedge clk_en);
	I_mask <= 1;
	repeat (4) @(posedge clk_en);
	nIRQ <= 1;
	repeat (4) @(posedge clk_en);
	I_mask <= 0;
	repeat (4) @(posedge clk_en);
	nIRQ <= 1;
	repeat (4) @(posedge clk_en);
	nIRQ <= 0;
	repeat (4) @(posedge clk_en);
	nIRQ <= 1;

	// Test NMI;
	repeat (4) @(posedge clk_en);
	nNMI <= 0;
	repeat (4) @(posedge clk_en);
	nNMI <= 1;
	repeat (4) @(posedge clk_en);
	NEXT_T <= 1;
	repeat (4) @(posedge clk_en);
	nNMI <= 0;
	repeat (4) @(posedge clk_en);
	nNMI <= 1;
	repeat (4) @(posedge clk_en);
	NEXT_T <= 0;
	repeat (4) @(posedge clk_en);
	nNMI <= 0;
	@(posedge clk_en);
	nNMI <= 1;
	repeat (36) @(posedge clk_en);
	$finish;
	end


endmodule // Interrupt_test
