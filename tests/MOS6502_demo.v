`timescale 1ns/1ns


module MOS6502_demo ();

`define CLK_PEROID 50
`define KiB64 	  16'hFFFF
`define RESET_VEC 16'hFFFC

initial $dumpvars(0, MOS6502_demo);

/**************************************************************************************************/

// input
reg nRES;
reg nIRQ;
reg nNMI;
reg nSO;
reg READY;
reg clk;
reg clk_en;
reg PHI_2;

// inout
wire [7:0] Data_bus = PHI_2 & RnW? mem_out : 8'hzz;

// output
wire [15:0] Address_bus;
wire SYNC;
wire RnW;

MOS6502 mos6502(
	.clk(clk),
	.clk_en(clk_en),
	.PHI_2(PHI_2),
	.nRESET(nRES),
	.nIRQ(nIRQ),
	.nNMI(nNMI),
	.nSO(nSO),
	.READY(READY),
	.Data_bus(Data_bus),
	.Address_bus(Address_bus),
	.RnW(RnW),
	.SYNC(SYNC));

// timing
initial clk = 0;
always #(`CLK_PEROID/2) clk = ~clk;
always @ (posedge clk or negedge clk) begin
	PHI_2  <= ~clk;
	clk_en <= #1 ~clk;
end

// memory
reg [7:0] mem [0:`KiB64];
reg [7:0] mem_out;

`include "demo_mem.vh"
always @ ( Data_bus, PHI_2, RnW, Address_bus )
	if(PHI_2)
		if(RnW) mem_out = mem[Address_bus];
		else	mem[Address_bus] = Data_bus;


// Termination
reg STOP = 0;
always @ (Address_bus, PHI_2, RnW)
	STOP = #5 STOP || Address_bus == `RESET_VEC && ~RnW && PHI_2;

/**************************************************************************************************/

initial begin

	nRES <= 0;
	nNMI <= 1;
	nIRQ <= 1;
	nSO <= 1;
	READY <= 1;
	repeat (5) @(posedge clk);
	
	nRES <= 1;
	@(posedge STOP)	#5 $finish;
end

endmodule
