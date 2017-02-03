module MC6845_test ();

initial $dumpvars(0, MC6845_test);

`define CLK_PEROID 10


// input
reg en;
reg nCS;
reg RnW;
reg RS;
reg nRESET;
reg LPSTB;
reg [7:0] data_in;

wire [7:0] data_bus = ~nCS&en&RnW? 8'hzz : data_in;

// output
wire [13:0] framestore_adr;
wire [4:0]  char_scanline;
wire display_en;
wire h_sync;
wire v_sync;
wire cursor;

MC6845 crtc(
	.char_clk(en), .en(en),
	.nCS(nCS), .RnW(RnW), .RS(RS),
	.nRESET(nRESET),
	.LPSTB(LPSTB),

	.data_bus(data_bus),

	.framestore_adr(framestore_adr),
	.char_scanline(char_scanline),
	.display_en(display_en),
	.h_sync(h_sync),
	.v_sync(v_sync),
	.cursor(cursor)
);

/**************************************************************************************************/

// The test will cover intended useage only: en & char_clk are derived from the same clock.
// While essentially they may be completely independent.

initial en = 0;
always #(`CLK_PEROID/2) en = ~en;

initial begin
	nRESET = 0;
	init_CRTC(
		101, 80, 86,  9,
		 24, 10, 24, 24,
		  0, 11,  0, 11,
		  0,128,  0, 128
	);

	
end


endmodule // MC6845_test
