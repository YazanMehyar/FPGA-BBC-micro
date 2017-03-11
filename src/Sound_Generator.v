module Sound_Generator (
	input clk,
	input clk_en,
	input nWE,
	input [7:0] DATA,

	output PWM);

	// NOTE: Initialisation of registers is used to aid with simulation

	reg [9:0] frequncy_1;
	reg [9:0] frequncy_2;
	reg [9:0] frequncy_3;
	reg [3:0] attenuator_1;
	reg [3:0] attenuator_2;
	reg [3:0] attenuator_3;
	reg [3:0] attenuator_N;
	reg [2:0] control_N;

	reg [2:0] ADR_REG;
	always @ (posedge clk)
		if(clk_en & ~nWE)
			if(~DATA[7]) begin
				casex (ADR_REG)
					3'b000: frequncy_1[9:4] <= DATA[5:0];
					3'b001: attenuator_1    <= DATA[3:0];
					3'b010: frequncy_2[9:4] <= DATA[5:0];
					3'b011: attenuator_2    <= DATA[3:0];
					3'b100: frequncy_3[9:4] <= DATA[5:0];
					3'b101: attenuator_3    <= DATA[3:0];
					3'b110: control_N       <= DATA[2:0];
					3'b111: attenuator_N    <= DATA[3:0];
				endcase
			end else begin
				case (DATA[6:4])
					3'b000: frequncy_1[3:0] <= DATA[3:0];
					3'b001: attenuator_1    <= DATA[3:0];
					3'b010: frequncy_2[3:0] <= DATA[3:0];
					3'b011: attenuator_2    <= DATA[3:0];
					3'b100: frequncy_3[3:0] <= DATA[3:0];
					3'b101: attenuator_3    <= DATA[3:0];
					3'b110: control_N       <= DATA[2:0];
					3'b111: attenuator_N    <= DATA[3:0];
				endcase
				ADR_REG <= DATA[6:4];
			end

/****************************************************************************************/
// DIVIDER

// The original SN76489 had a DIVIDER_16 rather than 8, but the clk_en here is half
// of that provided in the BEEB.

	reg [2:0] DIVIDER_8 = 0;
	always @ (posedge clk)
		if(clk_en) DIVIDER_8 <= DIVIDER_8 + 1;

	wire freq_en = ~|DIVIDER_8 & clk_en;

// TONE GENERATOR

	reg [9:0] fcount1 = 0;
	reg [9:0] fcount2 = 0;
	reg [9:0] fcount3 = 0;
	always @ (posedge clk)
		if(freq_en) begin
			`ifdef SIMULATION
				if(~nWE)			fcount1 <= 1;
				else if(~|fcount1)	fcount1 <= frequncy_1;
				else				fcount1 <= fcount1 - 1;

				if(~nWE)			fcount2 <= 1;
				else if(~|fcount2)	fcount2 <= frequncy_2;
				else				fcount2 <= fcount2 - 1;

				if(~nWE)			fcount3 <= 1;
				else if(~|fcount3)	fcount3 <= frequncy_3;
				else				fcount3 <= fcount3 - 1;
			`else
				if(~|fcount1)	fcount1 <= frequncy_1;
				else			fcount1 <= fcount1 - 1;

				if(~|fcount2)	fcount2 <= frequncy_2;
				else			fcount2 <= fcount2 - 1;

				if(~|fcount3)	fcount3 <= frequncy_3;
				else			fcount3 <= fcount3 - 1;
			`endif

		end

	reg oscillator_1 = 0;
	reg oscillator_2 = 0;
	reg oscillator_3 = 0;
	always @ (posedge clk) begin
		if(~|fcount1 & freq_en) oscillator_1 <= ~|frequncy_1? 1'b1 : ~oscillator_1;
		if(~|fcount2 & freq_en) oscillator_2 <= ~|frequncy_2? 1'b1 : ~oscillator_2;
		if(~|fcount3 & freq_en) oscillator_3 <= ~|frequncy_3? 1'b1 : ~oscillator_3;
	end

// NOISE GENERATOR

	reg [5:0] ncount = 0;
	always @ (posedge clk)
		if(freq_en) begin
			if(~|ncount | ~nWE) case (control_N[1:0])
				2'b00: ncount <= 6'h0F;
				2'b01: ncount <= 6'h1F;
				2'b10: ncount <= 6'h3F;
				default: ncount <= 6'h3F;
			endcase else ncount <= ncount - 1;
		end

	reg oscillator_n = 0;
	always @ (posedge clk)
		if(~|ncount & freq_en) oscillator_n <= ~oscillator_n;

	reg [14:0] LFSR;
	wire LFSR_RES = clk_en & ~nWE & (DATA[6:4] == 3'b110);
	wire SHIFT_en = freq_en & (&control_N[1:0]? ~|fcount3&oscillator_3 : ~|ncount&oscillator_n);
	always @ (posedge clk)
		if(LFSR_RES)		LFSR <= 15'h4000;
		else if(SHIFT_en)	LFSR <= {control_N[2]? ^LFSR[1:0] : LFSR[0], LFSR[14:1]};

/****************************************************************************************/
// Attenuators

	function [5:0] get_volume;
	input [3:0] attenuation;
	begin
		case (attenuation)
			4'h0: get_volume = 6'h3F;	4'h8: get_volume = 6'h0A;
			4'h1: get_volume = 6'h34;	4'h9: get_volume = 6'h08;
			4'h2: get_volume = 6'h28;	4'hA: get_volume = 6'h06;
			4'h3: get_volume = 6'h20;	4'hB: get_volume = 6'h05;
			4'h4: get_volume = 6'h19;	4'hC: get_volume = 6'h04;
			4'h5: get_volume = 6'h14;	4'hD: get_volume = 6'h03;
			4'h6: get_volume = 6'h10;	4'hE: get_volume = 6'h02;
			4'h7: get_volume = 6'h0D;	4'hF: get_volume = 6'h00;
			default: get_volume = 0;
		endcase;
	end
	endfunction


	wire [7:0] master_volume = (LFSR[0]? get_volume(attenuator_N) : 0)
								+ (oscillator_1? get_volume(attenuator_1) : 0)
								+ (oscillator_2? get_volume(attenuator_2) : 0)
								+ (oscillator_3? get_volume(attenuator_3) : 0);

// NOTE: clk_en is expected to pulse @ 2MHz for correct frequency
//		also for correct PWM. (2.08 MHz / 8 ~ 260KHz)

	reg [7:0] PWM_DUTY_COUNTER;
	always @ (posedge clk)
		if(freq_en) 				PWM_DUTY_COUNTER <= master_volume;
		else if(|PWM_DUTY_COUNTER)  PWM_DUTY_COUNTER <= PWM_DUTY_COUNTER - 1;

	assign PWM = |PWM_DUTY_COUNTER;
endmodule
