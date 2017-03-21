/*
	The following features were left out:
	- A2 Output mode
	- Shift register free run mode
	- Data latching mode
*/

`include "TOP.vh"

module MOS6522 (
	input clk,
	input clk_en,
	input CS1,
	input nCS2,
	input nRESET,
	input RnW,
	input [3:0] RS,
	input CA1,
	input CA2,
	inout CB1,
	inout CB2,

	inout [7:0] DATA,
	inout [7:0] PORTA,
	inout [7:0] PORTB,

	output nIRQ);

	reg [7:0] OUTA, DDRA;
	reg [7:0] OUTB, DDRB;
	reg [7:0] SR;
	reg [7:0] ACR, PCR;
	reg [15:0] T1COUNTER, T1REG;
	reg [15:0] T2COUNTER, T2REG;
	reg [6:0] IFR, IER;

	`ifdef SIMULATION
		initial begin
			T1COUNTER = 0;
			T2COUNTER = 0;
			T1REG = 0;
			T2REG = 0;
		end
	`endif

	wire CS = CS1&~nCS2;

/****************************************************************************************/

	// DATA OUT
	reg [7:0] DATA_OUT;
	assign DATA = (CS&RnW&nRESET)? DATA_OUT : 8'hzz;

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
			4'hA: DATA_OUT = SR;
			4'hB: DATA_OUT = ACR;
			4'hC: DATA_OUT = PCR;
			4'hD: DATA_OUT = {~nIRQ,IFR};
			4'hE: DATA_OUT = {1'b1,IER};
			default: DATA_OUT = 8'hxx;
		endcase else DATA_OUT = 8'hxx;
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
				4'h8: T2REG[7:0] <= DATA;
				4'hB: ACR  <= DATA;
				4'hC: PCR  <= DATA;
				4'hE: IER  <= DATA[7]? DATA[6:0] | IER : ~DATA[6:0] & IER;
			endcase
	end

/****************************************************************************************/
//	for CB1 look see end of file

	assign CB2 = nRESET&PCR[7]|ACR[4]?			CB2_out : 1'bz;

	wire INT_ACK = clk_en & ~CS;

	wire POSEDGE_CA1, NEGEDGE_CA1;
	Edge_Trigger #(0) CA1_NEG(.clk(clk),.IN(CA1),.En(INT_ACK),.EDGE(NEGEDGE_CA1));
	Edge_Trigger #(1) CA1_POS(.clk(clk),.IN(CA1),.En(INT_ACK),.EDGE(POSEDGE_CA1));

	wire POSEDGE_CA2, NEGEDGE_CA2;
	Edge_Trigger #(0) CA2_NEG(.clk(clk),.IN(CA2),.En(INT_ACK),.EDGE(NEGEDGE_CA2));
	Edge_Trigger #(1) CA2_POS(.clk(clk),.IN(CA2),.En(INT_ACK),.EDGE(POSEDGE_CA2));


	wire POSEDGE_CB1, NEGEDGE_CB1;
	Edge_Trigger #(0) CB1_NEG(.clk(clk),.IN(CB1),.En(INT_ACK),.EDGE(NEGEDGE_CB1));
	Edge_Trigger #(1) CB1_POS(.clk(clk),.IN(CB1),.En(INT_ACK),.EDGE(POSEDGE_CB1));

	wire POSEDGE_CB2, NEGEDGE_CB2;
	Edge_Trigger #(0) CB2_NEG(.clk(clk),.IN(CB2),.En(INT_ACK),.EDGE(NEGEDGE_CB2));
	Edge_Trigger #(1) CB2_POS(.clk(clk),.IN(CB2),.En(INT_ACK),.EDGE(POSEDGE_CB2));


	wire CA1INT = PCR[0]? POSEDGE_CA1 : NEGEDGE_CA1;
	wire CA2INT = PCR[2]? POSEDGE_CA2 : NEGEDGE_CA2;
	wire CB1INT = PCR[4]? POSEDGE_CB1 : NEGEDGE_CB1;
	wire CB2INT = PCR[6]? POSEDGE_CB2 : NEGEDGE_CB2;

/****************************************************************************************/
// HANDSHAKE & PULSE MODES

	reg CB1_out;
	reg CB2_out;

	wire ORB_WRITE = ~|RS & ~RnW & CS;

	always @ (posedge clk) begin
		if(ACR[4])
			CB2_out <= SR[7];
		else if(PCR[6])
			CB2_out <= PCR[5];
		else if(CB2_out)
			CB2_out <= ~ORB_WRITE;
		else
			CB2_out <= PCR[5]? clk_en : CB1INT;
	end

	wire CB1_TRIGGER = CB1_TRIGGER_FACTOR & SR_ACTIVE & ~SR_INT;

	reg CB1_TRIGGER_FACTOR;
	always @ (*) casex(ACR[4:2])
		3'b001: CB1_TRIGGER_FACTOR = ~|T2COUNTER[7:0];
		3'b10x: CB1_TRIGGER_FACTOR = ~|T2COUNTER[7:0];
		3'bx10: CB1_TRIGGER_FACTOR = clk_en;
		default:CB1_TRIGGER_FACTOR = 1'b0;
	endcase

	always @ (posedge clk)
		if(~nRESET)
			CB1_out <= 1;
		else if(CB1_TRIGGER & clk_en)
			CB1_out <= ~CB1_out;

/****************************************************************************************/
// SHIFTER

	wire POSSR_CB1, NEGSR_CB1;
	Edge_Trigger #(0) CB1_NEGSR(.clk(clk),.IN(CB1),.En(1'b1),.EDGE(NEGSR_CB1));
	Edge_Trigger #(1) CB1_POSSR(.clk(clk),.IN(CB1),.En(1'b1),.EDGE(POSSR_CB1));
	wire SR_EDGE   = ACR[4]? NEGSR_CB1 : POSSR_CB1;

	wire SR_ENABLE = |ACR[3:2];
	wire SR_IN     = ACR[4]? SR[7] : CB2;
	wire SR_ACCESS = CS && (RS==4'hA);

	reg SR_ACTIVE;
	always @ (posedge clk)
		if(~nRESET)
			SR_ACTIVE <= 0;
		else if(clk_en)
			if(~SR_ACTIVE) SR_ACTIVE <= SR_ACCESS & SR_ENABLE;
			else		   SR_ACTIVE <= |SR_COUNT;

	wire SR_INT_TRIGGER = SR_ENABLE & SR_ACTIVE & ~|SR_COUNT;
	wire SR_SHIFT		= (SR_ACTIVE|~SR_ENABLE) & SR_EDGE;
	reg [3:0] SR_COUNT;
	always @ (posedge clk)
		if(SR_ACCESS & clk_en) begin
			SR <= DATA;
			SR_COUNT <= 4'h8;
		end else if(SR_SHIFT) begin
			SR <= {SR[6:0],SR_IN};
			SR_COUNT <= SR_COUNT + 4'hF;
		end

/****************************************************************************************/
// T1COUNTER

	wire T1_INT_TRIGGER = ACR[6]?~|T1COUNTER:~|{PB7,T1COUNTER};
	wire T1_WRITE = CS && RS == 4'h5 && ~RnW;

	always @ (posedge clk)
		if(clk_en)
			if(T1_WRITE)
				T1COUNTER <= {DATA,T1REG[7:0]};
			else if(~|T1COUNTER)
				T1COUNTER <= T1REG;
			else if(clk_en)
				T1COUNTER <= T1COUNTER + 16'hFFFF;


	reg PB7;
	always @ (posedge clk)
		if(clk_en)
			if(ACR[6])		PB7 <= ~|T1COUNTER? ~PB7 : PB7;
			else if(PB7)	PB7 <= ~T1_WRITE;
			else			PB7 <= ~|T1COUNTER;


/****************************************************************************************/
// T2COUNTER

	wire PB6_NEGEDGE;
	wire T2_WRITE = CS && RS == 4'h9 && ~RnW;
	wire T2_INT_TRIGGER = ~|{nT2INTEn,T2COUNTER};

	Edge_Trigger #(0) PB6_NEG(.clk(clk),.IN(PORTB[6]),.En(clk_en),.EDGE(PB6_NEGEDGE));

	always @ (posedge clk)
		if(clk_en)
			if(T2_WRITE) begin
				T2COUNTER  <= {DATA,T2REG[7:0]};
				T2REG[15:8]<= DATA;
			end else if(~|T2COUNTER & ~ACR[5])
				T2COUNTER <= T2REG;
			else if(clk_en)
				if(ACR[5])	T2COUNTER <= T2COUNTER + {16{PB6_NEGEDGE}};
				else		T2COUNTER <= T2COUNTER + 16'hFFFF;

	reg nT2INTEn;
	always @ (posedge clk)
		if(clk_en)
			if(nT2INTEn) nT2INTEn <= ~T2_WRITE;
			else		 nT2INTEn <= ~|T2COUNTER;


/****************************************************************************************/
// Flag register

	wire T2_INT, T1_INT, SR_INT;
	Edge_Trigger #(1) POSEDGE_SR(.clk(clk),.IN(SR_INT_TRIGGER),.En(INT_ACK),.EDGE(SR_INT));
	Edge_Trigger #(1) POSEDGE_T2(.clk(clk),.IN(T2_INT_TRIGGER),.En(INT_ACK),.EDGE(T2_INT));
	Edge_Trigger #(1) POSEDGE_T1(.clk(clk),.IN(T1_INT_TRIGGER),.En(INT_ACK),.EDGE(T1_INT));


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
					4'h8:	   if(RnW) IFR[5] <= 1'b0;
					4'h9:	   if(~RnW)IFR[5] <= 1'b0;
					4'hA:	   IFR[2] <= 1'b0;
					4'hD:      if(~RnW) IFR <= ~DATA[6:0] & IFR;
			endcase else begin
				IFR[0] <= CA2INT | IFR[0];
				IFR[1] <= CA1INT | IFR[1];
				IFR[2] <= SR_INT | IFR[2];
				IFR[3] <= CB2INT | IFR[3];
				IFR[4] <= CB1INT | IFR[4];
				IFR[5] <= T2_INT | IFR[5];
				IFR[6] <= T1_INT | IFR[6];
			end
	end

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


	assign nIRQ = ~|(IFR&IER);

/****************************************************************************************/

	assign CB1 = nRESET&~&ACR[3:2]&|ACR[4:2]? CB1_out : DDRB[1]? 1'bz : 1;

endmodule // MOS6522
