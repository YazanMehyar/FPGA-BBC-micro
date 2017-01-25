module MOS_6502_stest ();

`define CLK_PEROID 50
`define KiB64 65535
`define RESET_VEC 16'hFFFC
`define NULL 0
`define TIME_LIMIT 200000000
`define TEST_FILE "./c_src/test_bin/6502_functional_test.bin"

initial $dumpvars(0, MOS_6502_stest);

reg STOP_SIG = 0;
reg clk = 0;
always clk = #(`CLK_PEROID/2) ~clk;

/**************************************************************************************************/

reg nRES, nIRQ, nNMI;
reg SO, READY;
reg [2:0] test_reg_select;

wire [15:0] Address_bus;
wire [7:0] test_value_out;
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
	.test_value_out(test_value_out)
	);

// memory
reg [7:0] mem [0:`KiB64];
reg [7:0] mem_out;
always @ ( Data_bus, PHI_2, RnW, Address_bus ) begin
	if(PHI_2) begin
		if(RnW) begin
			mem_out = mem[Address_bus];
		end else if(Address_bus == `RESET_VEC) begin
			STOP_SIG = 1;
		end else begin
			mem[Address_bus] = Data_bus;
			written = ~RnW;
			waddr = Address_bus;
		end
	end
end

/**************************************************************************************************/
integer adr, c, f;
task init_mem; begin

	f = $fopen(`TEST_FILE, "r");
	if(f == `NULL) begin
        $display("ERROR: Could not open file");
        $finish;
    end
	adr = 0;
	while(!$feof(f) && adr <= `KiB64) begin
		c[7:0] = $fgetc(f);
		if(!$feof(f)) begin
			mem[adr] = c[7:0];
			$write_mem(adr,c[7:0]);
		end
		adr = adr + 1;
	end
	$fclose(f);

end
endtask

reg [31:0] reg_names [0:8];
initial begin
	reg_names[3'd0] = "Acc";
	reg_names[3'd1] = "iX";
	reg_names[3'd2] = "iY";
	reg_names[3'd3] = "SP";
	reg_names[3'd4] = "PSR";
	reg_names[3'd5] = "PCL";
	reg_names[3'd6] = "PCH";
end

integer state, model_v, actual_v, i;
task error;
input [127:0] error_type;
begin
	$display("\n***************************************");
	$display("ERROR - %s @ %d ", error_type, $stime);
	$display("Address: %04H",i[15:0]);
	$display("Model Value:  %02H", model_v[7:0]);
	$display("Actual Value: %02H\n", actual_v[7:0]);
	$display("Internal state IND: %s", reg_names[i[2:0]]);
	$display("MODEL: %02H\tACTUAL:%02H", state[7:0], test_value_out);
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
		#1 if(test_value_out !== state) error("STATE MISMATCH");
	end

end
endtask

/******************************************************************************/
initial begin

	nRES <= 0;nNMI <= 1;nIRQ <= 1;SO <= 1;READY <= 1;
	init_mem;
	repeat (5) @(posedge clk);
	nRES <= 1;

	while(!SYNC) @(posedge clk);
	$reset_6502();
	while(!STOP_SIG && $time < `TIME_LIMIT) begin
		@(posedge clk) if(SYNC) begin
			@(posedge clk); $run_step(); check_mem;
		end
	end
	$finish;

end

endmodule // MOS_6502_test
