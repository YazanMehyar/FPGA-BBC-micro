module TOP_KEYBOARD(
    input CLK100MHZ,
    input PS2_CLK,
    input PS2_DATA,
    input CPU_RESETN,

    output [15:0] LED
    );

    // Show scan code hex of pressed key on LED
    wire GND = 1'b0;
    // Divide 100MHz clk
    reg [5:0] CLK_COUNT;
    always @ (posedge CLK100MHZ) CLK_COUNT <= CLK_COUNT + 1;
    // generate 1.5 MHz clk
    wire CLK1_5MHz = CLK_COUNT[5];
    
    wire COL_M;
    wire ROW_M;
    reg [6:0] key;
    
	assign LED[6:0] = COL_M&ROW_M? key : 6'h00; 
	
	always @ (posedge CLK1_5MHz)
	   key <= key + 1;
	      
    Keyboard k(
        .CLK_hPROC(CLK1_5MHz),
        .nRESET(CPU_RESETN),
        .autoscan(GND),
        .column(key[3:0]),
        .row(key[6:4]),

        .PS2_CLK(PS2_CLK),
        .PS2_DATA(PS2_DATA),
        
        .column_match(COL_M),
        .row_match(ROW_M));
endmodule
