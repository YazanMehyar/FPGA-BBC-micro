`include "TOP.vh"

module TOP(
	input CLK100MHZ,
	
	`ifdef NEXYS4
	input CPU_RESETN,
	output AUD_SD,
	`endif
	
	output AUD_PWM,

	input PS2_CLK,
	input PS2_DATA,

	output [3:0] VGA_R,
	output [3:0] VGA_G,
	output [3:0] VGA_B,
	output VGA_HS,
	output VGA_VS,

	output [1:0] LED,
	input  [4:0] SW, // [4] delay debugger
					 // [3] control break point
					 // [2] disable interrupts
					 // [1] set break point
					 // [0] display debugger
	input BTNU,
	input BTND,
	input BTNR,
	input BTNL,
	input BTNC,
	
	input [3:0] JOYSTICK_D,
	input [1:0] JOYSTICK_F,
	
	inout SCK,
	inout MISO,
	inout MOSI);
	
	`ifdef NEXYS4
	assign AUD_SD = 1'b1;
	`else
	reg CPU_RESETN = 1'b0;
	always @ (posedge CLK100MHZ) if(~CPU_RESETN) CPU_RESETN <= CLK_16en;
	`endif
	
	// Simulate 16MHz enable from 100 MHz clock
	wire DELAY_DEBUG = SW[4];
	wire CLK_16en;
	wire CLK_DBen;
	wire CLK_50en;
	
	`ifdef SIMULATION // Faster simulation
		reg [1:0]  COUNT3 = 0;
		always @ (posedge CLK100MHZ) begin
			if(COUNT3==2)	COUNT3 <= 0;
			else			COUNT3 <= COUNT3 + 1;
		
		end
	
		assign CLK_50en = 1'b1;
		assign CLK_DBen = COUNT3 == 0;
		assign CLK_16en = COUNT3 == 0;
	`else
		reg [10:0] COUNT1280 = 0;
		reg [2:0]  COUNT6    = 0;
		always @ (posedge CLK100MHZ) begin
			if(COUNT6==5)	COUNT6 <= 0;
			else			COUNT6 <= COUNT6 + 1;
		
			if(COUNT1280==1279) COUNT1280 <= 0;
			else			    COUNT1280 <= COUNT1280 + 1;
		
		end
	
		assign CLK_50en = COUNT6[0];
		assign CLK_DBen = COUNT6==5;
		assign CLK_16en = ~DELAY_DEBUG? COUNT6==5 : COUNT1280==1279;
	`endif


/**************************************************************************************************/

	wire [2:0] DEBUG_RGB;
	wire [2:0] RGB;
	wire VGA_NEWLINE;
	wire OUT_OF_SCREEN;
	wire HSYNC;
	wire VSYNC;
	wire DISEN;
	
	assign LED[0] = ~SCK;
	assign LED[1] = SW[3];


	BBC_MICRO beeb(
		.CLK(CLK100MHZ),
		.CLK_16en(CLK_16en),
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
		
		.CH(JOYSTICK_D),
		.PB(JOYSTICK_F),
		
		.SCK(SCK),
		.MISO(MISO),
		.MOSI(MOSI),
		
		.AUDIO_PWM(AUD_PWM),
		
		.DEBUG_CLK_en(CLK_50en),
		.DBUTTON_en(CLK_DBen),
		.DEBUG_ENABLE(OUT_OF_SCREEN),
		.DEBUG_NEWLINE(VGA_NEWLINE),
		.DEBUG_RGB(DEBUG_RGB)
	);
	
	// output
	wire [2:0] VGA_RGB;
	
	wire [2:0] PIXEL = OUT_OF_SCREEN? VGA_RGB^DEBUG_RGB : VGA_RGB;

	assign VGA_R = {4{PIXEL[0]}};
	assign VGA_G = {4{PIXEL[1]}};
	assign VGA_B = {4{PIXEL[2]}};
	
	VGA vga(
		.CLK(CLK100MHZ),
		.READ_en(CLK_50en),
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
