/****************************************************************
*
*	BBC microcomputer on FPGA
*
*	Yazan Mehyar	Email: stcyazanerror@gmail.com
*
*	Date 24-03-2017	
*
****************************************************************/


This project was intended to build an emulation of the bbc micro
on FPGA.

Currently the state of the project;

	+ Cycle accurate MOS6502
	+ MODEs 0 - 6 supported
	+ Sound produced using PWM
	+ Mapped USB Keyboard (Using PS2 interface provided by uController)
	+ Live Debug features (Using buttons and switches)
	+ SD card SPI interface (Using Pmods)

To run tests in the test file type:
	eg. To simulate TOP_test.v

	make TOP_test.sim

A simulation dump will be left in directory 'simdump'
The above line will cause TOP_test.lx2 to appear in 'simdump'
You can use 'gtkwave' to see the wave view.

WARNING: The 'docs' directory contains incomplete information.
		 It was left there in hopes of completing it one day.

Requirements:
	iverilog 10.x
	
	must create the following directories:
	- simdump
	- bin

---------------
END OF DOCUMENT
