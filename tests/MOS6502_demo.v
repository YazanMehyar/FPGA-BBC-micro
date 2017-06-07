`include "TOP.vh"

module MOS6502_demo ();

	`define RESET_VEC 16'hFFFC

	initial $dumpvars(0, MOS6502_demo);

/**************************************************************************************************/

	// input
	reg nRESET;
	reg nIRQ;
	reg nNMI;
	reg nSO;
	reg READY;
	reg CLK;
	wire CLK_en;

	// inout
	wire [7:0] Data_bus = RnW? mem_out : 8'hzz;

	// output
	wire [15:0] Address_bus;
	wire SYNC;
	wire RnW;

	MOS6502 mos6502(
		.CLK(CLK),
		.CLK_en(CLK_en),
		.nRESET(nRESET),
		.nIRQ(nIRQ),
		.nNMI(nNMI),
		.nSO(nSO),
		.READY(READY),
		.Data_bus(Data_bus),
		.Address_bus(Address_bus),
		.RnW(RnW),
		.SYNC(SYNC));

	// timing
	initial CLK = 0;
	always #(`CLKPERIOD/2) CLK = ~CLK;

	reg [3:0] CLK_count;
	initial CLK_count = 0;
	always @ (posedge CLK) CLK_count <= CLK_count + 1;
	assign CLK_en = &CLK_count;

	// memory
	reg [7:0] mem [0:`KiB64];
	reg [7:0] mem_out;

	`include "demo_mem.vh"

	always @ (posedge CLK)
		if(RnW) mem_out <= mem[Address_bus];
		else	mem[Address_bus] <= Data_bus;


	// Termination
	reg STOP = 0;
	always @ (posedge CLK)
		if(CLK_en)	STOP <= STOP || Address_bus == `RESET_VEC && ~RnW;

/**************************************************************************************************/

	initial begin

		nRESET <= 0;
		nNMI <= 1;
		nIRQ <= 1;
		nSO <= 1;
		READY <= 1;
		repeat (5) @(posedge CLK);

		nRESET <= 1;
		@(posedge STOP)	#5 $finish;
	end

endmodule
