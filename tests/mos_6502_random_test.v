module mos_6502_random_test ();

`define CLK_PEROID 50
`define KiB64 65535
`define RESET_VEC 16'hFFFC
`define NULL 0
`define TIME_LIMIT 1000000
`define SEEDs 10
integer SEED = 0;

initial $dumpvars(0, mos_6502_random_test);

reg clk = 0;
always clk = #(`CLK_PEROID/2) ~clk;

/**************************************************************************************************/

reg nRES, nIRQ, nNMI;
reg SO, READY;
reg [2:0] test_reg_select;

wire [15:0] Address_bus;
wire [7:0] test_value;
wire PHI_1, PHI_2;
wire SYNC, RnW;

wire [7:0] Data_bus = PHI_2 & RnW? mem_out : 8'hzz;

reg written = 0;
reg [15:0] waddr;
MOS_6502 mos6502(
	.clk(clk),
	.nRES(nRES), .nIRQ(nIRQ), .nNMI(nNMI),
	.SO(SO), .READY(READY),
	.Data_bus(Data_bus),
	.Address_bus(Address_bus),
	.PHI_1(PHI_1),
	.PHI_2(PHI_2),
	.RnW(RnW),
	.SYNC(SYNC),
	.test_reg_select(test_reg_select),
	.test_value(test_value)
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
		end else begin
			mem[Address_bus] = Data_bus;
			written = ~RnW;
			waddr = Address_bus;
		end
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

	opcode = $urandom(SEED) % 256;
	while(!is_valid(opcode)) opcode = $urandom(SEED) % 256;

end
endtask

reg [15:0] start_point;
task init_mem; begin
	for(i = 0; i <= `KiB64; i = i + 1) begin
		mem_val = $urandom(SEED) % 256;
		if(i == `RESET_VEC) begin
			start_point[7:0] = mem_val;
		end else if(i == `RESET_VEC + 1) begin
			start_point[15:8] = mem_val;
		end
		mem[i] = mem_val;
		$write_mem(i, mem_val);
	end
	mem[start_point] = 8'hA9; $write_mem(start_point, 8'hA9); start_point = start_point + 1;
	mem[start_point] = `NULL; $write_mem(start_point, `NULL); start_point = start_point + 1;// LDA #00
	mem[start_point] = 8'hA0; $write_mem(start_point, 8'hA0); start_point = start_point + 1;
	mem[start_point] = `NULL; $write_mem(start_point, `NULL); start_point = start_point + 1;// LDY #00
	mem[start_point] = 8'hA2; $write_mem(start_point, 8'hA2); start_point = start_point + 1;
	mem[start_point] = `NULL; $write_mem(start_point, `NULL); // LDX #00

end
endtask

reg [31:0] reg_names [2:0];
initial begin
	reg_names[0] = "Acc";
	reg_names[1] = "iX";
	reg_names[2] = "iY";
	reg_names[3] = "SP";
	reg_names[4] = "PSR";
	reg_names[5] = "PCL";
	reg_names[6] = "PCH";
end

reg [7:0] state;
integer model_v, actual_v;
task error;
input [127:0] error_type;
begin
	$display("\n***************************************");
	$display("ERROR - %s @ %d ", error_type, $stime);
	$display("Address: %04H",i[15:0]);
	$display("Model Value:  %02H", model_v[7:0]);
	$display("Actual Value: %02H\n", actual_v[7:0]);
	$display("Internal state IND: %s", reg_names[i[2:0]]);
	$display("MODEL: %02H\tACTUAL:%02H", state, test_value);
	$print_last_read();
	$display("***************************************\n");
	#1 $stop;
end
endtask

task check_mem; begin

	if(written) begin
		$read_mem(waddr, model_v);
		actual_v = mem[waddr];
		if(actual_v !== model_v) error("MEMORY MISMATCH");
		// check stack
		for(i = 16'h0100; i <= 16'h01ff; i = i + 1) begin
			$read_mem(i, model_v);
			actual_v = mem[i];
			if(actual_v !== model_v) error("MEMORY MISMATCH");
		end
	end

	written = 0;

	for(i = 0; i < 5; i = i + 1) begin
		test_reg_select = i;
		$get_internal_state(i, state);
		#1 if(test_value !== state) error("STATE MISMATCH");
	end

end
endtask

/******************************************************************************/
integer my_time = `TIME_LIMIT;
initial begin
	repeat(`SEEDs) begin
		SEED = SEED + 1;
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
		while($time < my_time) begin
			@(posedge clk) if(SYNC) begin
				@(posedge clk); $run_step(); check_mem;
			end
		end
		my_time = my_time+`TIME_LIMIT;
	end

	$finish;
end

endmodule // MOS_6502_test
