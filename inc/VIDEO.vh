`include "TOP.vh"

`define H_DISPLAY 2'b00
`define H_FRONT   2'b01
`define H_PULSE   2'b10
`define H_BACK    2'b11

`define V_DISPLAY 2'b00
`define V_FRONT   2'b01
`define V_PULSE   2'b10
`define V_BACK    2'b11

`ifdef SIMULATION

	// 640 x 480

	`define H_COUNTER_INIT 8'd49
	`define H_FRONT_COUNT  8'd10
	`define H_PULSE_COUNT  8'd9
	`define H_BACK_COUNT   8'd3

	`define V_COUNTER_INIT 10'd523
	`define V_FRONT_COUNT  10'd44
	`define V_PULSE_COUNT  10'd33
	`define V_BACK_COUNT   10'd31

`else

	// 800 x 600

	`define H_COUNTER_INIT 8'd64
	`define H_FRONT_COUNT  8'd15
	`define H_PULSE_COUNT  8'd12
	`define H_BACK_COUNT   8'd4

	`define V_COUNTER_INIT 10'd665
	`define V_FRONT_COUNT  10'd66
	`define V_PULSE_COUNT  10'd29
	`define V_BACK_COUNT   10'd23

`endif
