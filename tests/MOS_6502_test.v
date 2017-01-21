module MOS_6502_test ();

`define CLK_PEROID 10
`define KiB64 65535
`define STOP_ADR 16'hFFFC
`define TEST_FILE "./c_src/test_bin/bubble_sort.bin"
`define NULL 0

initial begin
	$dumpvars(0, MOS_6502_test);
end

reg clk = 0;
always clk = #(`CLK_PEROID/2) ~clk;

reg nRES, nIRQ, nNMI;
reg SO, READY;

wire [15:0] Address_bus;
wire PHI_1, PHI_2;
wire SYNC, RnW;

wire [7:0] Data_bus = PHI_2 & RnW? mem_out : 8'hzz;
MOS_6502 mos6502(
	.clk(clk),
	.nRES(nRES), .nIRQ(nIRQ), .nNMI(nNMI),
	.SO(SO), .READY(READY),
	.Data_bus(Data_bus),
	.Address_bus(Address_bus),
	.PHI_1(PHI_1),
	.PHI_2(PHI_2),
	.RnW(RnW),
	.SYNC(SYNC)
	);

// memory
reg [7:0] mem [0:`KiB64];
reg [7:0] mem_out;
reg STOP_SIG = 0;
always @ ( Data_bus, PHI_2, RnW, Address_bus ) begin
	if(PHI_2) begin
		if(RnW) mem_out = mem[Address_bus];
		else if(Address_bus == `STOP_ADR)
			STOP_SIG = 1;
		else mem[Address_bus] = Data_bus;
	end
end

/******************************************************************************/

integer f;
reg [7:0] c;
reg [16:0] adr;
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

integer j;
task print_results;
begin

	j = 0;
	while (j < 8) begin
		$display("%d: %h", j, mem[16'h0c00 + j]);
		j = j + 1;
	end

end
endtask

/******************************************************************************/

integer i;
initial begin
	nRES <= 0;
	nNMI <= 1;
	nIRQ <= 1;
	SO <= 1;
	READY <= 1;
	init_mem;
	repeat (5) @(posedge clk);

	nRES <= 1;
	while(!STOP_SIG && $time < 50000) @(posedge clk);

	print_results;
	$finish;

end

endmodule // MOS_6502_test
