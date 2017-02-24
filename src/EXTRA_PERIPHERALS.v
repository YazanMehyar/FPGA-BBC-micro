module EXTRA_PERIPHERALS (
	input clk2MHz,
	input nRESET,
	input RnW,
	input nVIA,
	input nACIA,
	input [13:0] cFRAMESTORE,
	input [2:0] cROWADDRESS,
	input LS259_D,
	input [2:0] LS259_A,

	inout  [7:0] DATABUS,
	output [14:0] CRTC_adr);

	assign DATABUS = (~nACIA&RnW&nRESET&~clk2MHz)? ACIA_status : 8'hzz;

// CRTC address correction
	wire B1 = ~&{LS259_reg[4],LS259_reg[5],cFRAMESTORE[12]};
	wire B2 = ~&{B3,LS259_reg[5],cFRAMESTORE[12]};
	wire B3 = ~&{LS259_reg[4],cFRAMESTORE[12]};
	wire B4 = ~&{B3,cFRAMESTORE[12]};

	wire [3:0] caa = cFRAMESTORE[11:8] + {B4,B3,B2,B1} + 1'b1; // CRTC adjusted address
	assign CRTC_adr = {caa[3],cFRAMESTORE[7:4],caa[2:0],cFRAMESTORE[3:0],cROWADDRESS[2:0]};

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

// VIA extention (partial behaviour)
	wire LS259en = nVIA;
	reg [7:0] LS259_reg;

	always @ ( posedge clk2MHz ) begin
		if(LS259en)	case (LS259_A)
			0:	LS259_reg[0] <= LS259_D;
			1:	LS259_reg[1] <= LS259_D;
			2:	LS259_reg[2] <= LS259_D;
			3:	LS259_reg[3] <= LS259_D;
			4:	LS259_reg[4] <= LS259_D;
			5:	LS259_reg[5] <= LS259_D;
			6:	LS259_reg[6] <= LS259_D;
			7:	LS259_reg[7] <= LS259_D;
		endcase
	end

// Keyboard

endmodule // EXTRA_PERIPHERALS
