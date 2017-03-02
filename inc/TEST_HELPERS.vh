// Task to simplify sending data via PS2
task PS2_SEND;
	input [7:0] DATA;
	begin
		@(posedge PS2_CLK);
		PS2_DATA <= 1'b0;

		repeat (8) begin
			@(posedge PS2_CLK);
			PS2_DATA <= DATA[0];
			DATA <= {DATA[0],DATA[7:1]};
		end

		@(posedge PS2_CLK);
		PS2_DATA <= ^DATA;

		@(posedge PS2_CLK);
		PS2_DATA <= 1'b1;
		@(posedge PS2_CLK);
	end
endtask

task PRESS_KEY;
	input [7:0] KEY;
	begin
		@(posedge PS2_CLK);
			PS2_SEND(KEY);
			$display("PRINTING %H", KEY);
		@(posedge VGA_VS);

		@(posedge PS2_CLK);
			PS2_SEND(8'hF0);
			PS2_SEND(KEY);
		repeat (3)	@(posedge VGA_VS);
	end
endtask
