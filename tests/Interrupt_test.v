module Interrupt_test ();
// input
reg clk;
reg NMI_pin;
reg IRQ_pin;
reg SO_pin;
reg RESET_pin;
reg RESET_req;
reg T0;
reg NEXT_T;
reg I_mask;

// output

wire NMI_req;
wire NMI_T0;
wire IRQ_req;
wire IRQ_T0;
wire SO_req;

Interrupt_6502 i(
	.clk(clk),
	.NMI_pin(NMI_pin),
	.IRQ_pin(IRQ_pin),
	.SO_pin(SO_pin),
	.RESET_pin(RESET_pin&RESET_req),
	.T0(T0),
	.NEXT_T(NEXT_T),
	.I_mask(I_mask),

	.NMI_req(NMI_req),
	.NMI_T0(NMI_T0),
	.IRQ_req(IRQ_req),
	.IRQ_T0(IRQ_T0),
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
IRQ_pin <= 1;
NMI_pin <= 1;
SO_pin  <= 1;

NEXT_T <= 0;
RESET_pin <= 0; // active low reset
repeat (3) @(posedge clk);
RESET_pin <= 1;

// Test IRQ
repeat (12) @(posedge clk);
IRQ_pin <= 0;
repeat (12) @(posedge clk);
I_mask <= 1;
repeat (12) @(posedge clk);
IRQ_pin <= 1;
repeat (12) @(posedge clk);
I_mask <= 0;
repeat (12) @(posedge clk);
IRQ_pin <= 1;
repeat (12) @(posedge clk);
IRQ_pin <= 0;
repeat (12) @(posedge clk);
IRQ_pin <= 1;

// Test NMI;
repeat (12) @(posedge clk);
NMI_pin <= 0;
repeat (12) @(posedge clk);
NMI_pin <= 1;
repeat (12) @(posedge clk);
NEXT_T <= 1;
repeat (12) @(posedge clk);
NMI_pin <= 0;
repeat (12) @(posedge clk);
NMI_pin <= 1;
repeat (12) @(posedge clk);
NEXT_T <= 0;
repeat (12) @(posedge clk);
NMI_pin <= 0;
@(posedge clk);
NMI_pin <= 1;
repeat (12) @(posedge clk);
$finish;
end


endmodule // Interrupt_test
