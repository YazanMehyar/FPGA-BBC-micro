`include "VIDEO.vh"

module VGA(
    input            CLK,
    input            READ_en,
    input            WRITE_en,
	input            VSYNC,
	input            HSYNC,
	input      [2:0] RGB,
	output reg       VGA_VSYNC,
	output reg       VGA_HSYNC,
	output reg [2:0] VGA_RGB,
	output reg 		 VGA_NEWLINE,
	output reg		 OUT_OF_SCREEN);

	
	`ifdef SIMULATION
		initial begin
			H_STATE   = 0;
			H_COUNTER = 0;
			V_STATE   = 0;
			V_COUNTER = 0;
			VGA_FIELD = 0;
		end
	`endif

// -- Horizontal Timing    
	reg  [1:0] H_STATE;
	reg [10:0] H_COUNTER;

	always @ (posedge CLK) if(READ_en) begin
        H_COUNTER <= ~|H_COUNTER? `H_COUNTER_INIT : H_COUNTER - 1;
        case (H_STATE)
            `H_BACK:   if(~|H_COUNTER)                  H_STATE <= `H_DISP;
            `H_PULSE:  if(H_COUNTER == `H_BACK_COUNT)   H_STATE <= `H_BACK;
            `H_FRONT:  if(H_COUNTER == `H_PULSE_COUNT)  H_STATE <= `H_PULSE;
            `H_DISP:   if(H_COUNTER == `H_FRONT_COUNT)  H_STATE <= `H_FRONT;
        endcase
	end

	wire NEWLINE = ~|H_COUNTER;

// -- Vertical Timing
	reg [1:0] V_STATE;
	reg [9:0] V_COUNTER;

	always @ (posedge CLK) if(NEWLINE&READ_en) begin
        V_COUNTER <= ~|V_COUNTER? `V_COUNTER_INIT : V_COUNTER - 1;

        case (V_STATE)
            `V_BACK:   if(~|V_COUNTER)                  V_STATE <= `V_DISP;
            `V_PULSE:  if(V_COUNTER == `V_BACK_COUNT)   V_STATE <= `V_BACK;
            `V_FRONT:  if(V_COUNTER == `V_PULSE_COUNT)  V_STATE <= `V_PULSE;
            `V_DISP:   if(V_COUNTER == `V_FRONT_COUNT)  V_STATE <= `V_FRONT;
        endcase
	end

	wire NEWSCREEN = ~|V_COUNTER & NEWLINE;
    wire VGA_DISEN = V_STATE == `V_DISP && H_STATE == `H_DISP;

    // Delay to fetch the pixel from memory
    always @ (posedge CLK) if(READ_en) begin
	    VGA_VSYNC <= V_STATE == `V_PULSE;
    	VGA_HSYNC <= H_STATE == `H_PULSE;
    end

/**************************************************************************************************/

    reg [9:0] READ_VADR;
    reg [8:0] WRITE_VADR;
    reg [9:0] READ_HADR, WRITE_HADR;
    reg		  VGA_FIELD;
    
    wire HSYNC_neg;
    Edge_Trigger #(0) nhsync_trigger(.CLK(CLK),.IN(HSYNC),.En(WRITE_en),.EDGE(HSYNC_neg));
    
    wire READ_STOP  = READ_VADR[9]&READ_VADR[6];
    wire WRITE_STOP = WRITE_VADR[8]&WRITE_VADR[5];
    

    always @ (posedge CLK) if(READ_en) begin
        if (NEWSCREEN) begin
        	READ_VADR <= 0;
        	READ_HADR <= 100;
        	VGA_FIELD <= ~VGA_FIELD;
        end else if(NEWLINE) begin
        	READ_VADR <= READ_VADR + (READ_STOP? 0 : 1);
        	READ_HADR <= 100;
        end else if(VGA_DISEN) begin
        	READ_HADR <= READ_HADR + (&READ_HADR[9:7]? 0 : 1);
        end
    end
    
    always @(posedge CLK) if(READ_en) begin
		VGA_NEWLINE   <= NEWLINE;
		OUT_OF_SCREEN <= READ_STOP;
    end
    
    always @ (posedge CLK) if(WRITE_en) begin
        if(VSYNC) begin
            WRITE_VADR <= 9'h1F0;
            WRITE_HADR <= 0;
        end else if(HSYNC_neg) begin
            WRITE_HADR <= 0;
            WRITE_VADR <= WRITE_VADR + (WRITE_VADR==288? 0 : 1);
        end else begin
            WRITE_HADR <= WRITE_HADR + (&WRITE_HADR[9:7]? 0 : 1);
        end
    end
    
	/*
		The VGA buffer overwrites the previous field as it captures the new one.
		As the buffer is read to display its pixels the reader returns 0 in
		alternating screens.
	*/    
    reg [2:0]  VGA_BUFFER [0:`VGA_BUFFER_SIZE];
    reg [18:0] WRITE_ADDRESS;
    reg [2:0]  COLOUR;
    always @ (posedge CLK) begin
    	if(WRITE_en) begin
    		WRITE_ADDRESS <= {WRITE_VADR,WRITE_HADR};
    		COLOUR <= RGB;
    		if(~WRITE_STOP)
				VGA_BUFFER[WRITE_ADDRESS] <= COLOUR;
    	end
    	if(READ_en)
    		if(&READ_HADR[9:7]|READ_STOP)
    			VGA_RGB <= 3'b000;
    		else if(VGA_FIELD~^READ_VADR[0])
    			VGA_RGB <= VGA_BUFFER[{READ_VADR[9:1],READ_HADR}];
    		else
    			VGA_RGB <= 3'b000;
   	end
   	
endmodule
