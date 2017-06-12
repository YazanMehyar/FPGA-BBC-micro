`include "TOP.vh"

module TOP(
	input CLK100MHZ,
	input CPU_RESETN,

	input PS2_CLK,
	input PS2_DATA,

	output [3:0] VGA_R,
	output [3:0] VGA_G,
	output [3:0] VGA_B,
	output VGA_HS,
	output VGA_VS,

	output [1:0] LED,
	input  [3:0] SW, // [3] control break point, [2] disable interrupts
					 // [1] set break point, [0] display debugger
	input BTNU,
	input BTND,
	input BTNR,
	input BTNL,
	input BTNC,
	
	output AUD_SD,
	output AUD_PWM,

	inout [9:7] JC);

	// Simulate VGA pixel scan rate
	reg CLK50MHZ = 0;
	always @ (posedge CLK100MHZ) CLK50MHZ <= ~CLK50MHZ;
	
	// Simulate 16MHz enable from 100 MHz clock
	reg [1:0] COUNT3 = 0;
	always @ (posedge CLK50MHZ) 
		if(COUNT3[1])	COUNT3 <= 0;
		else			COUNT3 <= COUNT3 + 1;
		
	// Simulate 6MHz enable from 100MHz clock
	reg [2:0] COUNT8 = 0;
	always @ (posedge CLK50MHZ) COUNT8 <= COUNT8 + 1;
	
	
	wire CLK_16en = COUNT3 == 0;
	wire CLK_6en  = COUNT8 == 0;


/**************************************************************************************************/

	wire [2:0] DEBUG_RGB;
	wire [2:0] RGB;
	wire VGA_NEWLINE;
	wire OUT_OF_SCREEN;
	wire HSYNC;
	wire VSYNC;
	wire FIELD;
	wire DISEN;
	
	assign LED[0] = JC[8];
	assign LED[1] = SW[3];


	BBC_MICRO beeb(
		.CLK(CLK50MHZ),
		.CLK_16en(CLK_16en),
		.CLK_6en(CLK_6en),
		.nRESET(CPU_RESETN),
		
		.PS2_CLK(PS2_CLK),
		.PS2_DATA(PS2_DATA),
		
		.RGB(RGB),
		.HSYNC(HSYNC),
		.VSYNC(VSYNC),
		
		.DISPLAY_DEBUGGER(SW[0]),
		.EN_BREAKPOINT(SW[1]),
		.DISABLE_INTERRUPTS(SW[2]),
		.SET_BREAKPOINT(SW[3]),
		
		.BUTTON_UP(BTNU),
		.BUTTON_DOWN(BTND),
		.BUTTON_LEFT(BTNL),
		.BUTTON_RIGHT(BTNR),
		.BUTTON_STEP(BTNC),
		
		.SCK(JC[7]),
		.MISO(JC[9]),
		.MOSI(JC[8]),
		
		.AUDIO_PWM(AUD_PWM),
		
		.DEBUG_CLK(CLK50MHZ),
		.DEBUG_ENABLE(OUT_OF_SCREEN),
		.DEBUG_NEWLINE(VGA_NEWLINE),
		.DEBUG_RGB(DEBUG_RGB)
	);
	
	assign AUD_SD = 1'b1;
	
	// output
	wire       VGA_VSYNC;
	wire       VGA_HSYNC;
	wire [2:0] VGA_RGB;
	
	wire [2:0] PIXEL = OUT_OF_SCREEN? VGA_RGB^DEBUG_RGB : VGA_RGB;

	assign VGA_R = {4{PIXEL[0]}};
	assign VGA_G = {4{PIXEL[1]}};
	assign VGA_B = {4{PIXEL[2]}};
	
	VGA vga(
		.CLK(CLK50MHZ),
		.READ_en(1'b1),
		.WRITE_en(CLK_16en),
		.VSYNC(VSYNC),
		.HSYNC(HSYNC),
		.RGB(RGB),
		.VGA_HSYNC(VGA_HS),
		.VGA_VSYNC(VGA_VS),
		.VGA_RGB(VGA_RGB),
		.VGA_NEWLINE(VGA_NEWLINE),
		.OUT_OF_SCREEN(OUT_OF_SCREEN)
	);

endmodule
