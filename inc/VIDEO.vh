`include "TOP.vh"

`define H_DISP   2'b00
`define H_FRONT  2'b01
`define H_PULSE  2'b10
`define H_BACK   2'b11

`define V_DISP   2'b00
`define V_FRONT  2'b01
`define V_PULSE  2'b10
`define V_BACK   2'b11

`define H_COUNTER_INIT 1039
`define H_FRONT_COUNT  240
`define H_PULSE_COUNT  184
`define H_BACK_COUNT   64

`define V_COUNTER_INIT 665
`define V_FRONT_COUNT  66
`define V_PULSE_COUNT  29
`define V_BACK_COUNT   23

`define VGA_BUFFER_SIZE (288*1024)-1
