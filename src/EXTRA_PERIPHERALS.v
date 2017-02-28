module EXTRA_PERIPHERALS (
	input CLK_PROC,
	input nRESET,
	input RnW,
	input nVIA,
	input nFDC,
	input nADC,
	input nTUBE,
	input nACIA,
	input nUVIA,

	inout  [7:0] DATABUS
	);

	assign DATABUS = (RnW&nRESET&~CLK_PROC)? (~nACIA)?	ACIA_status
											: (~(nUVIA&nFDC&nTUBE&nADC))?	8'h00
											: 8'hzz : 8'hzz;

// MOCK MC6850 ACIA
	reg [7:0] ACIA_status;
	initial begin
		ACIA_status[0] = 1;	// Most recent data is always ready
		ACIA_status[1] = 1;	// Most recent transfer is always done
		ACIA_status[2] = 0;	// Carrier is always detected
		ACIA_status[3] = 0;	// Always clear to send
		ACIA_status[4] = 0;	// No framing errors
		ACIA_status[5] = 0;	// No character overruns
		ACIA_status[6] = 0;	// No parity errors
		ACIA_status[7] = 0;	// No interrupts
	end

endmodule // EXTRA_PERIPHERALS
