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
