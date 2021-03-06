`include "TOP.vh"

module MOS6502_test ();

	`define STOP_ADR	16'hFFFC
	`define TEST_FILE	"./software/BIN/6502_functional_test.bin"
	`define NULL 0
	`define TIME_LIMIT	20000000

	reg CLK;
	reg nRESET;
	reg nIRQ;
	reg nNMI;
	reg nSO;
	reg READY;
	wire CLK_en;
	
	wire [7:0] Data_bus = RnW? mem_out : 8'hzz;

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
		.SYNC(SYNC)
	);
	
	initial $dumpvars(0, MOS6502_test);

	// Timing
	
	initial CLK = 0;
	always CLK = #(`CLKPERIOD/2) ~CLK;
	
	reg [3:0] CLK_count = 0;
	always @ (posedge CLK) CLK_count <= CLK_count + 1;
	assign CLK_en = &CLK_count;
	
	integer i;
	initial i = `TIME_LIMIT;
	always @ (posedge CLK)
		if(i == 0) $finish;
		else if(CLK_en) i <= i - 1;
	
	// memory
	reg [7:0] mem [0:`KiB64];
	reg [7:0] mem_out;
	reg STOP_SIG = 0;
	integer last_adr = 16'hFFFC;
	always @ (posedge CLK)
		if(RnW)
			mem_out <= mem[Address_bus];
		else if(Address_bus == `STOP_ADR)
			STOP_SIG <= 1;
		else
			mem[Address_bus] <= Data_bus;


	always @ (posedge CLK)
		if(CLK_en & SYNC) begin
			if(last_adr == Address_bus) $finish;
			last_adr <= Address_bus;
		end
	
/**************************************************************************************************/

	integer f;
	reg [7:0] c;
	integer adr;
	task init_mem; begin

		f = $fopen(`TEST_FILE, "r");
		if (f == `NULL) begin
		    $display("ERROR: Could not open file");
		    $finish;
		end
		adr = 0;
		while(!$feof(f) && adr <= `KiB64) begin
			c = $fgetc(f);
			if(!$feof(f)) mem[adr] = c;
			adr = adr + 1;
		end
		$fclose(f);

	end endtask

/**************************************************************************************************/

	initial begin
		nRESET <= 0;
		nNMI <= 1;
		nIRQ <= 1;
		nSO <= 1;
		READY <= 1;
		init_mem;
		repeat (5) @(posedge CLK);

		nRESET <= 1;
		while(!STOP_SIG) @(posedge CLK);

		$display("SUCCESS, Congratulations!");
		$finish;
	end

endmodule // MOS_6502_test
