`include "TOP.vh"
module Interrupt_test ();

	// input
	reg CLK;
	wire CLK_en;
	reg nNMI;
	reg nIRQ;
	reg nSO;
	reg nRESET;
	reg nRESET_req;
	reg NEXT_T;
	reg I_mask;

	// output
	wire nNMI_req;
	wire nIRQ_req;
	wire SO_req;

	MOS6502_Interrupt i(
		.CLK(CLK),
		.CLK_en(CLK_en),
		.nNMI(nNMI),
		.nIRQ(nIRQ),
		.nSO(nSO),
		.nRESET(nRESET&nRESET_req),
		.NEXT_T(NEXT_T),
		.I_mask(I_mask),

		.nNMI_req(nNMI_req),
		.nIRQ_req(nIRQ_req),
		.SO_req(SO_req)
	);

/****************************************************************************************/

	reg [3:0] CLK_count;
	initial begin
		$dumpvars(0,Interrupt_test);
		CLK = 0;
		CLK_count = 0;
	end

	always @ (posedge CLK) CLK_count <= CLK_count + 1;

	always #(`CLKPERIOD/2) CLK = ~CLK;
	assign CLK_en = &CLK_count;

/****************************************************************************************/

	reg T0;
	always @ (posedge CLK) begin
		if(CLK_en) begin
			NEXT_T <= $urandom_range(4,0)%5 == 0;
			T0 <= NEXT_T;
		end

		if(~nRESET)		nRESET_req	<= 1'b0;
		else if(CLK_en) nRESET_req	<= (nRESET_req | T0);
	end


	initial begin
	I_mask  <= 0;
	nIRQ <= 1;
	nNMI <= 1;
	nSO  <= 1;

	NEXT_T <= 0;
	T0 <= 0;
	nRESET <= 0; // active low reset
	repeat (3) @(posedge CLK);
	nRESET <= 1;

	// Test IRQ
	repeat (4) @(posedge CLK_en);
	nIRQ <= 0;
	repeat (4) @(posedge CLK_en);
	I_mask <= 1;
	repeat (4) @(posedge CLK_en);
	nIRQ <= 1;
	repeat (4) @(posedge CLK_en);
	I_mask <= 0;
	repeat (4) @(posedge CLK_en);
	nIRQ <= 0;
	repeat (4) @(posedge CLK_en);
	nIRQ <= 1;

	// Test NMI;
	repeat (4) @(posedge CLK_en);
	nNMI <= 0;
	repeat (4) @(posedge CLK_en);
	nNMI <= 1;
	repeat (8) @(posedge CLK_en);
	nNMI <= 0;
	repeat (4) @(posedge CLK_en);
	nNMI <= 1;
	repeat (8) @(posedge CLK_en);
	nNMI <= 0;
	@(posedge CLK_en);
	nNMI <= 1;
	repeat (36) @(posedge CLK_en);
	$finish;
	end


endmodule // Interrupt_test
