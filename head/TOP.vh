`ifndef TOP
`define TOP
	`define KiB16 14'h3FFF
	`define KiB32 15'h7FFF
	`define KiB64 16'hFFFF
	`define CLKPERIOD 10
	`ifdef SIMULATION
		`define NEXYS4
	`else
		`define BASYS3
	`endif

	`include "DEBUG_TOOL.vh"

	`timescale 1ns/1ns
`endif
