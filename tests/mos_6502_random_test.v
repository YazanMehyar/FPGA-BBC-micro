module mos_6502_random_test ();

`define CLK_PEROID 10
`define KiB64 65535
`define NULL 0
`define TIME_LIMIT 100000

initial $dumpvars(0, mos_6502_random_test);

reg clk = 0;
always clk = #(`CLK_PEROID/2) ~clk;

/**************************************************************************************************/

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

integer mem_val;
integer i;
// memory
reg [7:0] mem [0:`KiB64];
reg [7:0] mem_out;
always @ ( Data_bus, PHI_2, RnW, Address_bus ) begin
	if(PHI_2) begin
		if(RnW) begin
			mem_out = mem[Address_bus];
			if(SYNC && !is_valid(mem_out)) begin
				get_IR(mem_out);
				mem[Address_bus] = mem_out;
				$write_mem(Address_bus, mem_out);
			end
		end else mem[Address_bus] = Data_bus;
	end
end

/**************************************************************************************************/
function is_valid;
input [7:0] IR;
begin

	casex(IR) // 105 invalid instructions
		8'bxxxx_xx11, // 64
		8'b1000_0000, // 1 -- 65

		8'b0xxx_0010, // 8
		8'b11xx_0010, // 4
		8'b100x_0010, // 2
		8'b1011_0010, // 1 -- 15

		8'b01xx_0100, // 4
		8'b000x_0100, // 2
		8'b0011_0100, // 1
		8'b11x1_0100, // 2
		8'b1000_1001, // 1 -- 10

		8'b0xx1_1010, // 4
		8'b11x1_1010, // 2 -- 6

		8'b0xx1_1100, // 4
		8'b11x1_1100, // 2
		8'b0000_1100, // 1
		8'b1001_1100, // 1 -- 8

		8'b1001_1110: is_valid = 0;
		default: is_valid = IR !== 8'hxx;
	endcase

end
endfunction

task get_IR;
output [7:0] opcode;
begin

	opcode = $urandom_range(255,0);
	if(opcode < 50) begin
		// higher probability to store
		case(opcode[1:0])
			2'b11: opcode = 8'h08; // PHP
			2'b10: opcode = 8'h8C; // STY
			2'b01: opcode = 8'h8E; // STX
			default: opcode = 8'h8D; // STA
		endcase
	end else begin
		while(!is_valid(opcode)) opcode = $urandom_range(255,0);
	end

end
endtask

task init_mem; begin

	for(i = 0; i <= `KiB64; i = i + 1) begin
		mem_val = $urandom_range(255,0);
		mem[i] = mem_val;
		$write_mem(i, mem_val);
	end

end
endtask

task error;
begin
	$display("\n***************************************");
	$display("ERROR @ %d ", $stime);
	$display("***************************************\n");
	#1 $stop;
end
endtask

integer model_v, actual_v;
task check_mem; begin

	for(i = 0; i <= `KiB64; i = i + 1) begin
		model_v = $read_mem(i);
		actual_v = mem[i];
		if(actual_v != model_v) error;
	end

end
endtask

/******************************************************************************/
initial begin
	nRES <= 0;
	nNMI <= 1;
	nIRQ <= 1;
	SO <= 1;
	READY <= 1;
	init_mem;
	repeat (5) @(posedge clk);

	nRES <= 1;
	while(!SYNC) @(posedge clk);
	$reset_6502();
	while($time < `TIME_LIMIT) begin
		@(posedge clk) if(SYNC) begin
			$run_step();
			check_mem;
		end
	end

	$finish;
end

endmodule // MOS_6502_test
