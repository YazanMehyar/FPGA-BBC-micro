/**
*	NOTE: The module doesn't implement the whole functionality of the 6522.
	That is due to the fact that parts of the BBC micro developed
	which connected to these parts were dropped.

	The following features were left out:
	- Shift register (Some functionality implemented)
	- Handshake mode
	- Pulse mode
	- Data latching mode
	- T2 Timer
	- CA2 output modes
*/

`include "TOP.vh"

module MOS6522 (
	input clk,
	input clk_en,
	input clk_hen,
	input CS1,
	input nCS2,
	input nRESET,
	input PHI_2,
	input RnW,
	input [3:0] RS,
	input CA1,
	input CA2,
	inout CB1,
	input CB2,

	inout [7:0] DATA,
	inout [7:0] PORTA,
	inout [7:0] PORTB,

	output reg nIRQ);

	reg [7:0] OUTA, DDRA;
	reg [7:0] OUTB, DDRB;
	reg [7:0] SHIFT;
	reg [7:0] ACR, PCR;
	reg [15:0] T1COUNTER, T1REG;
	reg [7:0]  T2REG;
	reg [15:0] T2COUNTER;
	reg [6:0] IFR, IER;

	wire CS = CS1&~nCS2;

/****************************************************************************************/

	// DATA OUT
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
			4'h7: DATA_OUT = T1REG[15:8];
			4'h8: DATA_OUT = T2COUNTER[7:0];
			4'h9: DATA_OUT = T2COUNTER[15:8];
			4'hA: DATA_OUT = SHIFT;
			4'hB: DATA_OUT = ACR;
			4'hC: DATA_OUT = PCR;
			4'hD: DATA_OUT = {~nIRQ,IFR};
			4'hE: DATA_OUT = {1'b1,IER};
			default: DATA_OUT = 8'hxx;
		endcase
	end

/****************************************************************************************/

	// Most Internal Registers
	always @ (posedge clk) begin
		if(~nRESET) begin
			ACR  <= 0;  PCR <= 0;
			DDRA <= 0; DDRB <= 0;
			IER  <= 0;
		end else if(clk_en)
			if(CS & ~RnW) case (RS)
				4'h0: OUTB <= DATA;
				4'h1,
				4'hF: OUTA <= DATA;
				4'h2: DDRB <= DATA;
				4'h3: DDRA <= DATA;
				4'h4,
				4'h6: T1REG[7:0] <= DATA;
				4'h7: T1REG[15:8]<= DATA;
				4'h8: T2REG<= DATA;
				4'hB: ACR  <= DATA;
				4'hC: PCR  <= DATA;
				4'hE: IER  <= DATA[7]? DATA[6:0] | IER : ~DATA[6:0] & IER;
			endcase
	end

/****************************************************************************************/

	wire POSEDGE_CA1, NEGEDGE_CA1;
	Edge_Trigger #(0) CA1_NEG(.clk(clk),.IN(CA1),.EDGE(NEGEDGE_CA1));
	Edge_Trigger #(1) CA1_POS(.clk(clk),.IN(CA1),.EDGE(POSEDGE_CA1));
		
	wire POSEDGE_CA2, NEGEDGE_CA2;
	Edge_Trigger #(0) CA2_NEG(.clk(clk),.IN(CA2),.EDGE(NEGEDGE_CA2));
	Edge_Trigger #(1) CA2_POS(.clk(clk),.IN(CA2),.EDGE(POSEDGE_CA2));
		
		
	wire POSEDGE_CB1, NEGEDGE_CB1;
	Edge_Trigger #(0) CB1_NEG(.clk(clk),.IN(CB1),.EDGE(NEGEDGE_CB1));
	Edge_Trigger #(1) CB1_POS(.clk(clk),.IN(CB1),.EDGE(POSEDGE_CB1));
		
	wire POSEDGE_CB2, NEGEDGE_CB2;
	Edge_Trigger #(0) CB2_NEG(.clk(clk),.IN(CB2),.EDGE(NEGEDGE_CB2));
	Edge_Trigger #(1) CB2_POS(.clk(clk),.IN(CB2),.EDGE(POSEDGE_CB2));
		
		
	
/****************************************************************************************/
	wire INT_ACK = clk_en & ~CS;
// -- A side

	reg CA1INT;
	always @ (posedge clk)
		if(~nRESET|IFR[1])			CA1INT <= 0;
		else if(~CA1INT|INT_ACK)	CA1INT <= PCR[0]? POSEDGE_CA1 : NEGEDGE_CA1;


	reg CA2INT;
	always @ (posedge clk)
		if(~nRESET|IFR[0])			CA2INT <= 0;
		else if(~CA2INT|INT_ACK)	CA2INT <= PCR[2]? POSEDGE_CA2 : NEGEDGE_CA2;

// -- B side
	
	reg CB1INT;
	always @ (posedge clk)
		if(~nRESET|IFR[4])			CB1INT <= 0;
		else if(~CB1INT|INT_ACK)	CB1INT <= PCR[4]? POSEDGE_CB1 : NEGEDGE_CB1;


	reg CB2INT;
	always @ (posedge clk)
		if(~nRESET|IFR[3])			CB2INT <= 0;
		else if(~CB2INT|INT_ACK)	CB2INT <= PCR[6]? POSEDGE_CB2 : NEGEDGE_CB2;

/****************************************************************************************/
// Flag register

	wire INDEPENDANT_CB2 = ~PCR[7] & PCR[5];
	wire INDEPENDANT_CA2 = ~PCR[3] & PCR[1];

	always @ (posedge clk) begin
		if(~nRESET)	begin
			IFR <= 0;
		end else if(clk_en)
			if(CS) case (RS) // Write
					4'h0:	   IFR[4:3] <= {1'b0, INDEPENDANT_CB2? IFR[3] : 1'b0};
					4'h1,4'hF: IFR[1:0] <= {1'b0, INDEPENDANT_CA2? IFR[0] : 1'b0};
					4'h4:	   if(RnW) IFR[6] <= 1'b0;
					4'h5:      if(~RnW)IFR[6] <= 1'b0;
					4'hD:      if(~RnW)IFR    <= ~DATA[6:0] & IFR;
			endcase else begin
				IFR[0] <= CA2INT | IFR[0];
				IFR[1] <= CA1INT | IFR[1];
				IFR[2] <= SHIFTER_IRQ | IFR[2];
				IFR[3] <= CB2INT | IFR[3];
				IFR[4] <= CB1INT | IFR[4];
				IFR[6] <= ~|T1COUNTER | IFR[6];
			end
	end
	
/****************************************************************************************/
// Shift register

	assign CB1 = SHIFT_MODE2? CB1_CLK : 1'bz;

	wire SHIFT_ACCES = CS && RS == 4'hA;
	wire SHIFT_MODE0 = ACR[4:2] == 3'b000;
	wire SHIFT_MODE2 = ACR[4:2] == 3'b010;
	
	reg [2:0] SHIFT_COUNT;
	reg CB1_CLK;
	reg SHIFT_COUNTING;
	reg SHIFTER_IRQ;
	reg CB1_POSEDGE;
	
	always @ (posedge clk)
		if(~nRESET) SHIFTER_IRQ <= 0;
		else if(clk_en) SHIFTER_IRQ <= ~|SHIFT_COUNT & SHIFT_COUNTING;
	
	always @ (posedge clk)
		if(~nRESET)
			CB1_POSEDGE <= 0;
		else if(~CB1_POSEDGE|clk_hen)
			CB1_POSEDGE <= POSEDGE_CB1;
	
	always @ (posedge clk)
		if(clk_en)
			if(SHIFT_ACCES) begin
				SHIFT_COUNT <= 3'h7;
				CB1_CLK		<= 1;
				SHIFT		<= DATA;
				SHIFT_COUNTING <= 1;
			end
		else if(clk_hen) begin
			if(~CB1_CLK | SHIFT_COUNTING)
				CB1_CLK <= ~CB1_CLK;
			
			SHIFT_COUNTING <= |SHIFT_COUNT;
			
			if(~CB1_CLK & |SHIFT_COUNT)
				SHIFT_COUNT <= SHIFT_COUNT + 3'h7;
				
			if(SHIFT_MODE0)
				SHIFT <= CB1_POSEDGE? {SHIFT[6:0],CB2} : SHIFT;
			else if(SHIFT_MODE2)
				SHIFT <= ~CB1_CLK?    {SHIFT[6:0],CB2} : SHIFT;
				
		end
	
/****************************************************************************************/
// T1COUNTER

	wire T1_WRITE = CS && RS == 4'h5 && ~RnW;
	always @ (posedge clk)
		if(clk_en)
			if(T1_WRITE)
				T1COUNTER <= {DATA,T1REG[7:0]};
			else if(~|T1COUNTER)
				T1COUNTER <= T1REG;
			else if(clk_hen)
				T1COUNTER <= T1COUNTER + 16'hFFFF;
				
				
	reg PB7;
	always @ (posedge clk)
		if(clk_en)
			if(ACR[6]) begin
				if(~T1COUNTER) PB7 <= ~PB7;
			end else begin
				if(PB7)	PB7 <= ~T1_WRITE;
				else	PB7 <= ~|T1COUNTER;
			end
			
/****************************************************************************************/
// T2COUNTER


/****************************************************************************************/

	assign PORTA = nRESET?
					{DDRA[7]? OUTA[7]: 1'bz, DDRA[6]? OUTA[6]: 1'bz,
					DDRA[5]? OUTA[5]: 1'bz, DDRA[4]? OUTA[4]: 1'bz,
					DDRA[3]? OUTA[3]: 1'bz, DDRA[2]? OUTA[2]: 1'bz,
					DDRA[1]? OUTA[1]: 1'bz, DDRA[0]? OUTA[0]: 1'bz} : 8'hzz;

	assign PORTB = nRESET?
					{DDRB[7]? ACR[7]? PB7:OUTB[7]:1'bz, DDRB[6]? OUTB[6]:1'bz,
					DDRB[5]? OUTB[5]:1'bz, DDRB[4]? OUTB[4]:1'bz,
					DDRB[3]? OUTB[3]:1'bz, DDRB[2]? OUTB[2]:1'bz,
					DDRB[1]? OUTB[1]:1'bz, DDRB[0]? OUTB[0]:1'bz} : 8'hzz;
		

	always @ (posedge clk) begin
		nIRQ <= ~|(IFR&IER);
	end

endmodule // MOS6522
