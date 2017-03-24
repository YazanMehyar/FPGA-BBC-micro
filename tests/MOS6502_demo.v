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
	reg clk;
	wire clk_en;

	// inout
	wire [7:0] Data_bus = RnW? mem_out : 8'hzz;

	// output
	wire [15:0] Address_bus;
	wire SYNC;
	wire RnW;

	MOS6502 mos6502(
		.clk(clk),
		.clk_en(clk_en),
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
	initial clk = 0;
	always #(`CLKPERIOD/2) clk = ~clk;

	reg [3:0] clk_count;
	initial clk_count = 0;
	always @ (posedge clk) clk_count <= clk_count + 1;
	assign clk_en = &clk_count;

	// memory
	reg [7:0] mem [0:`KiB64];
	reg [7:0] mem_out;

	`include "demo_mem.vh"

	always @ (posedge clk)
		if(RnW) mem_out <= mem[Address_bus];
		else	mem[Address_bus] <= Data_bus;


	// Termination
	reg STOP = 0;
	always @ (posedge clk)
		if(clk_en)	STOP <= STOP || Address_bus == `RESET_VEC && ~RnW;

/**************************************************************************************************/

	initial begin

		nRESET <= 0;
		nNMI <= 1;
		nIRQ <= 1;
		nSO <= 1;
		READY <= 1;
		repeat (5) @(posedge clk);

		nRESET <= 1;
		@(posedge STOP)	#5 $finish;
	end

endmodule
