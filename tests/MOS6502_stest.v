`include "TOP.vh"

module MOS6502_stest ();

	`define NULL 0
	`define RESET_VEC	16'hFFFC
	`define TEST_FILE	"./software/BIN/6502_functional_test.bin"

	reg CLK;
	reg nRESET;
	reg nIRQ;
	reg nNMI;
	reg nSO;
	reg READY;
	reg [3:0] DEBUG_SEL;
	wire CLK_en;

	wire [7:0] Data_bus = RnW? mem_out : 8'hzz;

	wire [15:0] Address_bus;
	wire [15:0] DEBUG_VAL;
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
		.SYNC(SYNC),
		.DEBUG_SEL(DEBUG_SEL),
		.DEBUG_VAL(DEBUG_VAL)
	);

	//initial $dumpvars(0, MOS6502_stest);

	reg STOP_SIG = 0;
	initial CLK = 0;
	always CLK = #(`CLKPERIOD/2) ~CLK;

	reg [3:0] CLK_count = 0;
	always @ (posedge CLK)	CLK_count <= CLK_count + 1;
	assign CLK_en = &CLK_count;

/**************************************************************************************************/
	// memory
	reg [7:0] mem [0:`KiB64];
	reg [7:0] mem_out;
	always @ (posedge CLK)
		if(RnW) begin
			mem_out <= mem[Address_bus];
		end else if(Address_bus == `RESET_VEC) begin
			STOP_SIG <= 1;
		end else begin
			mem[Address_bus] <= Data_bus;
			written <= ~RnW;
			waddr <= Address_bus;
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
		reg_names[3'd5] = "PC";
	end

	integer state, model_v, actual_v, i;
	reg written = 0;
	reg [15:0] waddr;
	task check_mem; begin

		if(written) begin
			$read_mem(waddr, model_v);
			actual_v = mem[waddr];
			if(actual_v !== model_v) begin
				$display("\n***************************************");
				$display("ERROR - MEMORY MISMATCH @ %d ", $time);
				$display("Address: %04H",waddr[15:0]);
				$display("Model Value:  %02H", model_v[7:0]);
				$display("Actual Value: %02H\n", actual_v[7:0]);
				$print_last_read();
				$display("***************************************\n");
				#1 $stop;
			end
			// check stack
			for(i = 16'h0100; i <= 16'h01ff; i = i + 1) begin
				$read_mem(i, model_v);
				actual_v = mem[i];
				if(actual_v !== model_v) begin
					$display("\n***************************************");
					$display("ERROR - STACK MISMATCH @ %d ", $time);
					$display("Address: %04H",i[15:0]);
					$display("Model Value:  %02H", model_v[7:0]);
					$display("Actual Value: %02H\n", actual_v[7:0]);
					$print_last_read();
					$display("***************************************\n");
					#1 $stop;
				end
			end
		end

		written = 0;

		for(i = 0; i < 5; i = i + 1) begin
			DEBUG_SEL = i;
			$get_internal_state(i, state);
			#1 if(DEBUG_VAL !== state) begin
				$display("\n***************************************");
				$display("ERROR - REGISTER MISMATCH @ %d ", $time);
				$display("Internal state IND: %s", reg_names[i[2:0]]);
				$display("MODEL: %02H\nACTUAL:%02H", state[7:0], DEBUG_VAL);
				$print_last_read();
				$display("***************************************\n");
				#1 $stop;
			end
		end

	end
	endtask

/**************************************************************************************************/

	initial begin

		nRESET <= 0;
		nNMI <= 1;
		nIRQ <= 1;
		nSO  <= 1;
		READY <= 1;
		init_mem;
		repeat (5) @(posedge CLK);
		nRESET <= 1;

		while(!(SYNC&CLK_en)) @(posedge CLK);

		$reset_6502();

		while(!STOP_SIG) @(posedge CLK)
			if(SYNC&CLK_en) begin
				@(posedge CLK);
				while(!CLK_en) @(posedge CLK);
				$run_step();
				check_mem;
			end

		$finish;

	end

endmodule // MOS_6502_test
