module MC6845_test ();

`define H_TOTAL		0
`define H_DISPLAY	1
`define H_SYNCPOS	2

`define VH_PULSE	3
`define V_TOTAL		4
`define V_FRACTION	5
`define V_DISPLAY	6
`define V_SYNCPOS	7

`define INTERLACE	8
`define MAX_SCANLINE 9
`define	CURSOR_START 10
`define CURSOR_END	11

`define START_ADDRESS_HI 12
`define START_ADDRESS_LO 13
`define CURSOR_ADDRESS_HI 14
`define CURSOR_ADDRESS_LO 15

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
wire [4:0]  scanline_row;
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
	.scanline_row(scanline_row),
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

integer count;

task set_reg;
	input [3:0] reg_adr;
	input [7:0] reg_data;
	begin
		RS <= 0; RnW <= 0; nCS <= 0;
		data_in <= reg_adr;
		@(posedge en);
		RS <= 1; RnW <= 0; nCS <= 0;
		data_in <= reg_data;
		@(posedge en);
	end
endtask

initial begin
	nRESET <= 0;
	@(posedge en);
	set_reg(`H_TOTAL, 24);
	set_reg(`H_DISPLAY, 16);
	set_reg(`H_SYNCPOS, 20);
	set_reg(`VH_PULSE, 3);
	set_reg(`V_TOTAL, 18);
	set_reg(`V_FRACTION, 20);
	set_reg(`V_DISPLAY, 12);
	set_reg(`V_SYNCPOS, 16);
	set_reg(`INTERLACE, 0);
	set_reg(`MAX_SCANLINE, 9);
	set_reg(`CURSOR_START, 0);
	set_reg(`CURSOR_END, 9);
	set_reg(`START_ADDRESS_HI, 0);
	set_reg(`START_ADDRESS_LO, 128);
	set_reg(`CURSOR_ADDRESS_HI, 0);
	set_reg(`CURSOR_ADDRESS_LO, 128);
	nRESET <= 1;
	nCS <= 1;
	repeat(200) @(posedge en);
	$finish;
end


endmodule // MC6845_test
