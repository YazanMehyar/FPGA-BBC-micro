module TELETEXT_5050(
    input       CLK,
    input       SA_F1,
    input		SA_T6,
    input       VSYNC,
    input       HSYNC,
    input       LOSE,
    input [6:0] DATABUS,
    output[2:0] RGB);

    reg  [6:0] SA_code;
    reg  [3:0] SA_row;
    
    reg  [2:0] SA_gcolour;
    reg  [2:0] SA_acolour;
    reg  [2:0] SA_bcolour;
    
    reg  	   SA_gcontiguous;
    reg	 [1:0] SA_double;
    reg		   SA_doubleA;
    reg		   SA_flash;
    reg		   SA_GRAPHICS;
	
/**************************************************************************************************/	
	wire HSYNC_DROP;
    wire NEW_ROW = HSYNC_DROP && SA_row == 9;
	Edge_Trigger #(0) hsync_neg(.CLK(CLK),.IN(HSYNC),.En(SA_F1),.EDGE(HSYNC_DROP));
	
	reg [19:0] FLASH_COUNTER = 0;
	always @ (posedge CLK) if(SA_F1) begin
		FLASH_COUNTER <= FLASH_COUNTER + 1;
	end
	
	always @ (posedge CLK) if(SA_F1) begin
		case(SA_double)
		2'b00: if(LOSE) 	SA_double <= (SA_code == 7'b000_1101)? 2'b01 : 2'b00;
		2'b01: if(NEW_ROW)	SA_double <= 2'b10;
		2'b10: if(NEW_ROW)	SA_double <= 2'b00;
		default: SA_double <= 2'b00;
		endcase
	end
	
	always @ (posedge CLK) if(SA_F1) begin
		if(NEW_ROW) begin
			SA_acolour     <= 3'b111;
			SA_gcontiguous <= 1;
			SA_flash       <= 0;
			SA_doubleA	   <= 0;
			SA_bcolour	   <= 0;
			SA_GRAPHICS	   <= 0;
		end else if(LOSE)
			if(~|SA_code[6:5]) casex(SA_code[4:0])
			5'b0_0xxx: if(|SA_code[2:0]) SA_acolour <= SA_code[2:0];
			5'b0_100x: SA_flash   <= ~SA_code[0];
			5'b0_110x: SA_doubleA <=  SA_code[0];
			5'b1_0xxx: if(|SA_code[2:0]) SA_gcolour <= SA_code[2:0];
			5'b1_1001: begin SA_gcontiguous <= 1; SA_GRAPHICS <= 1; end
			5'b1_1010: begin SA_gcontiguous <= 0; SA_GRAPHICS <= 1; end
			5'b1_1100: SA_bcolour <= 3'b000;
			5'b1_1101: SA_bcolour <= SA_acolour;
		endcase
	end 
		
/**************************************************************************************************/
// Beware of pipelining effect, colour changes will affect the previous character;

    reg  [5:0] SA_dots;
    reg  [5:0] SA_shifter;
    wire [5:0] SA_alphadots;
    wire [5:0] SA_graphicdots;
    
    reg  [1:0] SA_LOSE;
    reg  [1:0] SA_G2;
    reg  [2:0] SA_alphaC;
    reg  [2:0] SA_graphicC;
	reg  [1:0] g_segment;
    reg  [3:0] SA_line;
     
	always @ (*) if(SA_doubleA) begin
		if(SA_double[0]) SA_line = {1'b0,SA_row[3:1]};
		else case(SA_row[3:1])
			3'h0: SA_line = 4'h5;
			3'h1: SA_line = 4'h6;
			3'h2: SA_line = 4'h7;
			3'h3: SA_line = 4'h8;
			3'h4: SA_line = 4'h9;
			default: SA_line = 4'h9;
		endcase
	end else SA_line = SA_row;
     
	always @ (*) case(SA_line)
		4'h0,4'h1:			 g_segment={SA_code[0],SA_code[1]};
		4'h2:				 g_segment= SA_gcontiguous? {SA_code[0],SA_code[1]}:2'b00;
		4'h3,4'h4,4'h5:		 g_segment={SA_code[2],SA_code[3]};
		4'h6:				 g_segment= SA_gcontiguous? {SA_code[2],SA_code[3]}:2'b00;
		4'h7,4'h8:			 g_segment={SA_code[4],SA_code[6]};
		4'h9:				 g_segment= SA_gcontiguous? {SA_code[4],SA_code[6]}:2'b00;
		default:			 g_segment=2'b00;
	endcase

	assign SA_graphicdots = {SA_gcontiguous&g_segment[1],g_segment[1],g_segment[1],
							SA_gcontiguous&g_segment[0],g_segment[0],g_segment[0]};
							 

    SA_ROM char_rom(.code(SA_code),.line(SA_line),.pattern(SA_alphadots));
    
							 
    always @ (posedge CLK) if(SA_F1) begin
        SA_code <= DATABUS;
        SA_dots <= SA_GRAPHICS&SA_code[5]? SA_graphicdots : SA_alphadots;
        SA_LOSE <= {SA_LOSE[0],LOSE};
        SA_G2   <= {SA_G2[0],SA_GRAPHICS&SA_code[5]};
        SA_alphaC   <= SA_acolour;
        SA_graphicC <= SA_gcolour;
    end
    
    always @ (posedge CLK) begin
    	if(SA_F1)		SA_shifter <= SA_dots;
		else if(SA_T6)	SA_shifter <= SA_shifter << 1;
	end
	
    always @ (posedge CLK) if(SA_F1) begin
        if(VSYNC)     
        	SA_row <= 0;
        else if(HSYNC_DROP)
        	SA_row <= (SA_row == 9)? 0 : SA_row + 1;
    end
    wire FLASH = |FLASH_COUNTER[19:18] & SA_flash;
	wire [2:0] SA_fcolour = SA_G2[1]? SA_graphicC : SA_alphaC;
    assign RGB = SA_LOSE[1]? SA_shifter[5]? FLASH? ~SA_fcolour : SA_fcolour : SA_bcolour:3'b000;

endmodule
