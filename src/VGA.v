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
	output reg [2:0] VGA_RGB);

	
	`ifdef SIMULATION
		initial begin
			H_STATE   = 0;
			H_COUNTER = 0;
			V_STATE   = 0;
			V_COUNTER = 0;
			FIELD     = 0;
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

	wire NEWLINE = ~|H_COUNTER & READ_en;

// -- Vertical Timing
	reg [1:0] V_STATE;
	reg [9:0] V_COUNTER;

	always @ (posedge CLK) if(NEWLINE) begin
        V_COUNTER <= ~|V_COUNTER? `V_COUNTER_INIT : V_COUNTER - 1;

        case (V_STATE)
            `V_BACK:   if(~|V_COUNTER)                  V_STATE <= `V_DISP;
            `V_PULSE:  if(V_COUNTER == `V_BACK_COUNT)   V_STATE <= `V_BACK;
            `V_FRONT:  if(V_COUNTER == `V_PULSE_COUNT)  V_STATE <= `V_PULSE;
            `V_DISP:   if(V_COUNTER == `V_FRONT_COUNT)  V_STATE <= `V_FRONT;
        endcase
	end

	wire NEWSCREEN = ~|V_COUNTER & NEWLINE;
    wire DISEN     = V_STATE == `V_DISP && H_STATE == `H_DISP;

    // Delay to fetch the pixel from memory
    always @ (posedge CLK) if(READ_en) begin
	    VGA_VSYNC <= V_STATE == `V_PULSE;
    	VGA_HSYNC <= H_STATE == `H_PULSE;
    end

/******************************************************************************/

    reg [18:0] READ_ADR, WRITE_ADR, nWRITE_ADR;
    reg  [2:0] VGA_COLOUR;
    reg  [2:0] VGA_BUFFER [0:`VGA_BUFFER_SIZE];

    wire HSYNC_neg;
    wire VSYNC_neg;
    Edge_Trigger #(0) nvsync_trigger(.CLK(CLK),.IN(VSYNC),.En(WRITE_en),.EDGE(VSYNC_neg));
    Edge_Trigger #(0) nhsync_trigger(.CLK(CLK),.IN(HSYNC),.En(WRITE_en),.EDGE(HSYNC_neg));

    always @ (posedge CLK) if(READ_en) begin
        if (NEWSCREEN) READ_ADR <= 0;
        else if(DISEN) READ_ADR <= READ_ADR+1;
    end

    always @ (posedge CLK) if(WRITE_en) begin
        if(VSYNC_neg) begin
            WRITE_ADR  <= FIELD? `VGA_BUFFER_W     : 0;
            nWRITE_ADR <= FIELD? {`VGA_BUFFER_W,0} :`VGA_BUFFER_W;
            FIELD      <= ~FIELD;
        end else if(HSYNC_neg) begin
            WRITE_ADR  <= nWRITE_ADR;
            nWRITE_ADR <= nWRITE_ADR+`VGA_BUFFER_W;
        end else begin
            WRITE_ADR  <= WRITE_ADR+(WRITE_ADR!=nWRITE_ADR);
        end
    end

endmodule
