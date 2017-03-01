module PS2_DRIVER(
	input CLK,
	input nRESET,
	input PS2_CLK,
	input PS2_DATA,

	output reg [7:0] DATA,
	output reg DONE);

/****************************************************************************************/
	
	reg  prev_PS2CLK;
	always @ (posedge CLK) prev_PS2CLK <= PS2_CLK;
	
	wire NEGEDGE_PS2_CLK = prev_PS2CLK & ~PS2_CLK;
	
/****************************************************************************************/

    reg [10:0] MESSAGE;
    wire wDONE = MESSAGE[10]&~MESSAGE[0]&~^MESSAGE[9:1];
    always @ (posedge CLK) begin
        if(~nRESET | DONE)
            MESSAGE <= 11'hFFF;
        else if(NEGEDGE_PS2_CLK)
            MESSAGE <= {PS2_DATA,MESSAGE[10:1]};
          
        if(~nRESET | DONE)
            DONE <= 0;
		else
            DONE <= wDONE;
            
        if(wDONE)    
            DATA <= MESSAGE[8:1];
    end
    

endmodule
