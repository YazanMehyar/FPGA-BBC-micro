/**
*	NOTE: The module doesn't implement the whole functionality of the 6522.
	That is due to the fact that parts of the BBC micro developed
	which connected to these parts were dropped.

	The following features were left out:
	- Interrupt controls CB1, CB2
	- Shift register
	- Handshake mode
	- Pulse mode
	- Data latching mode
	- Timer 1 PB7 output
	- T2 Timer
	- Independent interrupt mode
	- CA2 output modes
*/

`include "TOP.vh"

module MOS6522 (
	input CS1,
	input nCS2,
	input nRESET,
	input PHI_2,
	input RnW,
	input [3:0] RS,
	input CA1,
	input CA2,

	inout [7:0] DATA,
	inout [7:0] PORTA,
	inout [7:0] PORTB,

	output reg nIRQ);

	reg [7:0] OUTA, DDRA;
	reg [7:0] OUTB, DDRB;
	reg [7:0] ACR, PCR;
	reg [15:0] T1COUNTER, T1REG;
	reg [6:0] IFR, IER;

	wire CS = CS1&~nCS2;

/****************************************************************************************/

	// DATA
	reg [7:0] DATA_OUT;
	assign DATA = (PHI_2&CS&RnW&nRESET)? DATA_OUT : 8'hzz;

	always @ (*) begin
		if(CS) case (RS)
			4'h0: DATA_OUT = nRESET?
					{DDRB[7]? OUTB[7]:PORTB[7], DDRB[6]? OUTB[6]:PORTB[6],
					DDRB[5]? OUTB[5]:PORTB[5], DDRB[4]? OUTB[4]:PORTB[4],
					DDRB[3]? OUTB[3]:PORTB[3], DDRB[2]? OUTB[2]:PORTB[2],
					DDRB[1]? OUTB[1]:PORTB[1], DDRB[0]? OUTB[0]:PORTB[0]} : 8'hzz;
			4'h1,
			4'hF: DATA_OUT = nRESET?
					{DDRA[7]? OUTA[7]:PORTA[7], DDRA[6]? OUTA[6]:PORTA[6],
					DDRA[5]? OUTA[5]:PORTA[5], DDRA[4]? OUTA[4]:PORTA[4],
					DDRA[3]? OUTA[3]:PORTA[3], DDRA[2]? OUTA[2]:PORTA[2],
					DDRA[1]? OUTA[1]:PORTA[1], DDRA[0]? OUTA[0]:PORTA[0]} : 8'hzz;
			4'h2: DATA_OUT = DDRB;
			4'h3: DATA_OUT = DDRA;
			4'h4: DATA_OUT = T1COUNTER[7:0];
			4'h5: DATA_OUT = T1COUNTER[15:8];
			4'h6: DATA_OUT = T1REG[7:0];
			4'hB: DATA_OUT = ACR;
			4'hC: DATA_OUT = PCR;
			4'hD: DATA_OUT = {~nIRQ,IFR};
			4'hE: DATA_OUT = {1'b1,IER};
			default: DATA_OUT = 8'hxx;
		endcase
	end

/****************************************************************************************/

	// Most Internal Registers
	always @ (negedge PHI_2) begin
		if(~nRESET) begin
			ACR <= 0; PCR <= 0;
			DDRA <= 0; DDRB <= 0;
			OUTB <= 0; OUTA <= 0;
			IER <= 0;
		end else if(CS & ~RnW) case (RS)
			4'h0: OUTB <= DATA;
			4'h1,
			4'hF: OUTA <= DATA;
			4'h2: DDRB <= DATA;
			4'h3: DDRA <= DATA;
			4'h4,
			4'h6: T1REG[7:0] <= DATA;
			4'h7: T1REG[15:8]<= DATA;
			4'hB: ACR  <= DATA;
			4'hC: PCR  <= DATA;
			4'hE: IER  <= DATA[7]? DATA[6:0] | IER : ~DATA[6:0] & IER;
		endcase
	end

/****************************************************************************************/

	reg CA1INT_pos, CA1INT_neg, CA1INT;
	always @ (posedge CA1 or posedge IFR[1]) begin
		if(IFR[1]) CA1INT_pos <= 0;
		else CA1INT_pos <= 1;
	end

	always @ (negedge CA1 or posedge IFR[1]) begin
		if(IFR[1]) CA1INT_neg <= 0;
		else CA1INT_neg <= 1;
	end

	always @ (negedge PHI_2) begin
		if(~nRESET) CA1INT <= 0;
		else 		CA1INT <= PCR[0]? CA1INT_pos : CA1INT_neg;
	end


	reg CA2INT_pos, CA2INT_neg, CA2INT;
	always @ (posedge CA2 or posedge IFR[0]) begin
		if(IFR[0]) CA2INT_pos <= 0;
		else CA2INT_pos <= 1;
	end

	always @ (negedge CA2 or posedge IFR[0]) begin
		if(IFR[0]) CA2INT_neg <= 0;
		else CA2INT_neg <= 1;
	end

	always @ (negedge PHI_2) begin
		if(~nRESET) CA2INT <= 0;
		else 		CA2INT <= PCR[2]? CA2INT_pos : CA2INT_neg;
	end

/****************************************************************************************/

	always @ (negedge PHI_2) begin
		if(~nRESET)	begin
			IFR <= 0;
		end else if(CS) begin
			case (RS) // Write
				4'h1,4'hF: IFR[1:0] <= 2'b00;
				4'h4:      if(RnW) IFR[6] <= 1'b0;
				4'h5:      if(~RnW)IFR[6] <= 1'b0;
				4'hD:      if(~RnW)IFR    <= ~DATA[6:0] & IFR;
			endcase
		end else begin
			IFR[0] <= CA2INT | IFR[0];
			IFR[1] <= CA1INT | IFR[1];
			IFR[6] <= T1INT & ~|T1COUNTER  | IFR[6];
		end
	end

/****************************************************************************************/

	reg T1INT, T1IRQ;
	always @ (negedge PHI_2) begin
		if(~nRESET) begin
			T1INT    <= 0;
			T1COUNTER<= 0;
			T1IRQ    <= 0;
		end else if(CS && RS==4'h5 && ~RnW) begin
			T1COUNTER<= {DATA,T1REG[7:0]};
			T1INT    <= 1;
			T1IRQ    <= 0;
		end else begin
			T1IRQ <= T1INT & ~|T1COUNTER;

			if(~|T1COUNTER) T1COUNTER <= T1REG;
			else if(~T1IRQ)	T1COUNTER <= T1COUNTER + 16'hFFFF;
		end
	end

/****************************************************************************************/


	assign PORTA = nRESET?
					{DDRA[7]? OUTA[7]: 1'bz, DDRA[6]? OUTA[6]: 1'bz,
					DDRA[5]? OUTA[5]: 1'bz, DDRA[4]? OUTA[4]: 1'bz,
					DDRA[3]? OUTA[3]: 1'bz, DDRA[2]? OUTA[2]: 1'bz,
					DDRA[1]? OUTA[1]: 1'bz, DDRA[0]? OUTA[0]: 1'bz} : 8'hzz;

	assign PORTB = nRESET?
					{DDRB[7]? OUTB[7]: 1'bz, DDRB[6]? OUTB[6]: 1'bz,
					DDRB[5]? OUTB[5]: 1'bz, DDRB[4]? OUTB[4]: 1'bz,
					DDRB[3]? OUTB[3]: 1'bz, DDRB[2]? OUTB[2]: 1'bz,
					DDRB[1]? OUTB[1]: 1'bz, DDRB[0]? OUTB[0]: 1'bz} : 8'hzz;

	always @ (posedge PHI_2) begin
		nIRQ <= ~|(IFR&IER);
	end

endmodule // MOS6522
