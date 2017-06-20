module Filter #(
	parameter DEBOUNCE_COUNT = 0,
	parameter PRESET_VALUE   = 0,
	parameter INPUT_WIDTH    = 1
)(
	input							CLK,
	input							CLK_en,
	input							READY_en,
	input							nRESET,
	input 		[INPUT_WIDTH-1:0]	SIGNAL,
	output reg	[INPUT_WIDTH-1:0]	FILTERED_SIGNAL,
	output reg						READY
);

	
	reg [3:0] counter;
	reg [INPUT_WIDTH-1:0] signal_last_state;
	
	always @ (posedge CLK or negedge nRESET)
		if(~nRESET) begin
			FILTERED_SIGNAL   <= PRESET_VALUE;
			signal_last_state <= PRESET_VALUE;
		end else if(CLK_en) begin
			signal_last_state <= SIGNAL;
			if(counter == DEBOUNCE_COUNT)
				FILTERED_SIGNAL <= signal_last_state;
		end
		
	always @ (posedge CLK or negedge nRESET)
		if(~nRESET)
			counter <= 0;
		else if(CLK_en) begin
			if(counter == DEBOUNCE_COUNT || SIGNAL != signal_last_state)
				counter <= 0;
			else
				counter <= counter + 1;
		end
		
	always @ (posedge CLK or negedge nRESET)
		if(~nRESET)
			READY <= 0;
		else if(READY_en) begin
			if(counter == DEBOUNCE_COUNT)
				READY <= CLK_en;
			else
				READY <= 0;
		end

endmodule
