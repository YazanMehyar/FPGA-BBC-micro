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

/**************************************************************************************************/
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
    reg [7:0] READ_HADR, WRITE_HADR;
    reg		  VGA_FIELD;
    
    wire HSYNC_neg;
    Edge_Trigger #(0) nhsync_trigger(.CLK(CLK),.IN(HSYNC),.En(WRITE_en),.EDGE(HSYNC_neg));
    
    wire READ_STOP  = READ_VADR[9] &READ_VADR[6];
    reg  [1:0] RCOUNT = 0, WCOUNT = 0;
    wire WRITE_STORE = (WCOUNT == 2) && WRITE_en;
    wire LOAD_en     = (RCOUNT == 0) && READ_en;
    
    always @ (posedge CLK) begin
    	if(READ_en)  RCOUNT <= RCOUNT + 1;
    	if(WRITE_en) WCOUNT <= WCOUNT + 1;
    end
    

    always @ (posedge CLK) if(READ_en) begin
        if (NEWSCREEN) begin
        	READ_VADR <= 0;
        	READ_HADR <= 25;
        	VGA_FIELD <= ~VGA_FIELD;
        end else if(NEWLINE) begin
        	READ_VADR <= READ_VADR + (READ_STOP? 0 : 1);
        	READ_HADR <= 25;
        end else if(VGA_DISEN) begin
        	READ_HADR <= READ_HADR + LOAD_en;
        end
    end
    
    always @ (posedge CLK) if(READ_en) begin
		VGA_NEWLINE   <= NEWLINE;
		OUT_OF_SCREEN <= READ_STOP;
    end
    
    always @ (posedge CLK) if(WRITE_en) begin
        if(VSYNC) begin
            WRITE_VADR <= 9'h1E8;
            WRITE_HADR <= 0;
        end else if(HSYNC_neg) begin
            WRITE_HADR <= 0;
            if(WRITE_VADR!=288)
            	WRITE_VADR <= WRITE_VADR + 1;
        end else if(WRITE_STORE) begin
            WRITE_HADR <= WRITE_HADR + 1;
        end
    end
    
	/*
		The VGA buffer overwrites the previous field as it captures the new one.
		As the buffer is read to display its pixels the reader returns 0 in
		alternating screens.
	*/    
    reg [11:0] VGA_BUFFER [0:`VGA_BUFFER_SIZE];
    reg [16:0] WRITE_ADDRESS, READ_ADDRESS;
    reg [11:0] WRITE_SHIFT, READ_SHIFT;
    reg [11:0] READ_RGB;
    
    always @ (posedge CLK) if(READ_en) begin
		if(VGA_FIELD^READ_VADR[0])
			VGA_RGB <= 3'b000;
		else
			VGA_RGB <= READ_SHIFT[11:9];
			
    	if(LOAD_en)
    		READ_SHIFT <= READ_RGB;
		else
    		READ_SHIFT <= READ_SHIFT << 3;
    		
    	if(LOAD_en) READ_ADDRESS <= {READ_VADR[9:1],READ_HADR};
    		
    end
    
    always @ (posedge CLK) if(WRITE_en) begin
		if(WRITE_STORE)
			WRITE_ADDRESS <= {WRITE_VADR,WRITE_HADR};
		
		WRITE_SHIFT   <= {WRITE_SHIFT[8:0],RGB};
    end
    	
    
    always @ (posedge CLK) begin
    	if(LOAD_en)
    		READ_RGB <= VGA_BUFFER[READ_ADDRESS];
    	else if(WRITE_STORE)
    		VGA_BUFFER[WRITE_ADDRESS] <= WRITE_SHIFT;
   	end
   	
endmodule
