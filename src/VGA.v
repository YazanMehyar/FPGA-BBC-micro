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
	output	   [2:0] VGA_RGB,
	output reg 		 VGA_NEWLINE,
	output reg		 OUT_OF_SCREEN);

	
	`ifdef SIMULATION
		initial begin
			H_STATE   = 0;
			H_COUNTER = 0;
			V_STATE   = 0;
			V_COUNTER = 0;
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
    reg [9:0] READ_HADR, WRITE_HADR;
    
    wire READ_STOP = READ_VADR[9]&READ_VADR[6];
    wire HSYNC_neg, VSYNC_neg;
    Edge_Trigger #(0) nvsync_trigger(.CLK(CLK),.IN(VSYNC),.En(WRITE_en),.EDGE(VSYNC_neg));
    Edge_Trigger #(0) nhsync_trigger(.CLK(CLK),.IN(HSYNC),.En(WRITE_en),.EDGE(HSYNC_neg));

    always @ (posedge CLK) if(READ_en) begin
        if (NEWSCREEN) begin
        	READ_VADR <= 0;
        	READ_HADR <= 120;
        end else if(NEWLINE) begin
        	READ_VADR <= READ_VADR + (READ_STOP? 0 : 1);
        	READ_HADR <= 120;
        end else if(VGA_DISEN) begin
        	READ_HADR <= READ_HADR + 1;
        end
    end
    
    always @ (posedge CLK) if(READ_en) begin
		VGA_NEWLINE   <= NEWLINE;
		OUT_OF_SCREEN <= READ_STOP;
    end
    
    always @ (posedge CLK) if(WRITE_en) begin
        if(VSYNC_neg) begin
            WRITE_VADR <= 9'h1E8;
            WRITE_HADR <= 0;
        end else if(HSYNC_neg) begin
            WRITE_HADR <= 0;
            WRITE_VADR <= WRITE_VADR + 1;
        end else begin
            WRITE_HADR <= WRITE_HADR + 1;
        end
    end
    
    reg [2:0]  VGA_BUFFER_1 [0:256*1024-1];
    reg [2:0]  VGA_BUFFER_2 [0:32*1024-1];
    reg [18:0] WRITE_ADDRESS, READ_ADDRESS;
    reg [2:0]  READ_RGB1, READ_RGB2, COLOUR;
    
    always @ (posedge CLK) if(READ_en) begin			
    	READ_ADDRESS <= {READ_VADR[9:1],READ_HADR};
    end
    
    always @ (posedge CLK) if(WRITE_en) begin
		WRITE_ADDRESS <= {WRITE_VADR,WRITE_HADR};
		COLOUR <= RGB;
    end
    	
    assign VGA_RGB = READ_ADDRESS[18]? READ_RGB2 : READ_RGB1;
    
    always @ (posedge CLK) begin
    	if(READ_en)
    		if(READ_STOP)			  READ_RGB2 <= 3'b000;
    		else if(READ_ADDRESS[18]) READ_RGB2 <= VGA_BUFFER_2[READ_ADDRESS[14:0]];
    		else				 	  READ_RGB1 <= VGA_BUFFER_1[READ_ADDRESS[17:0]];
    		
    	if(WRITE_en)
    		if(WRITE_ADDRESS[18]) begin
    			if(~|WRITE_ADDRESS[17:15])
    				 VGA_BUFFER_2[WRITE_ADDRESS[14:0]] <= COLOUR;
    		end else VGA_BUFFER_1[WRITE_ADDRESS[17:0]] <= COLOUR;
   	end
   	
endmodule
