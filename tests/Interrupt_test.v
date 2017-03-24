module Interrupt_test ();
// input
reg clk;
reg nNMI;
reg nIRQ;
reg nSO;
reg nRESET;
reg RESET_req;
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
	.nNMI(nNMI),
	.nIRQ(nIRQ),
	.nSO(nSO),
	.nRESET(nRESET&RESET_req),
	.T0(T0),
	.NEXT_T(NEXT_T),
	.I_mask(I_mask),

	.nNMI_req(nNMI_req),
	.nNMI_T0(nNMI_T0),
	.nIRQ_req(nIRQ_req),
	.nIRQ_T0(nIRQ_T0),
	.SO_req(SO_req));

`define CLK_PERIOD 10

initial begin
$dumpvars(0,Interrupt_test);
clk = 0;
end
always #(`CLK_PERIOD/2) clk = ~clk;

always @ (posedge clk) begin
	T0 <= $urandom_range(4,0)%5 == 0;
end

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
repeat (12) @(posedge clk);
nIRQ <= 0;
repeat (12) @(posedge clk);
I_mask <= 1;
repeat (12) @(posedge clk);
nIRQ <= 1;
repeat (12) @(posedge clk);
I_mask <= 0;
repeat (12) @(posedge clk);
nIRQ <= 1;
repeat (12) @(posedge clk);
nIRQ <= 0;
repeat (12) @(posedge clk);
nIRQ <= 1;

// Test NMI;
repeat (12) @(posedge clk);
nNMI <= 0;
repeat (12) @(posedge clk);
nNMI <= 1;
repeat (12) @(posedge clk);
NEXT_T <= 1;
repeat (12) @(posedge clk);
nNMI <= 0;
repeat (12) @(posedge clk);
nNMI <= 1;
repeat (12) @(posedge clk);
NEXT_T <= 0;
repeat (12) @(posedge clk);
nNMI <= 0;
@(posedge clk);
nNMI <= 1;
repeat (12) @(posedge clk);
$finish;
end


endmodule // Interrupt_test
