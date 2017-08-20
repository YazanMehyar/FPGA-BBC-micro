/****************************************************************
*
*	BBC microcomputer on FPGA
*
*	Yazan Mehyar	Email: stcyazanerror@gmail.com
*
*	Date 20-08-2017	
*
****************************************************************/


This project was intended to build an emulation of the bbc micro
on FPGA.

Currently the state of the project;

	+ Cycle accurate MOS6502
	+ Sound produced using PWM
	+ Mapped USB Keyboard (Using PS2 interface provided by uController)
	+ Live Debug features (Using buttons and switches)
	+ SD card SPI interface (Using Pmods)
	+ Joystick emulation

To run tests in the test file type:
	eg. To simulate TOP_test.v

	make TOP_test.sim

A simulation dump will be left in directory 'simdump'
The above line will cause TOP_test.lx2 to appear in 'simdump'
You can use 'gtkwave' to see the wave view.

The implementation can be made to work on different types of boards
by changing the relevant user constraint file appropriately. I have
added support to 2 boards namely [NEXYS4,BASYS3]. Simply define
the name in TOP.vh in the 'inc' directory to have it accomodate the chosen
board. You will still have to the modify board's the user constraint file.

WARNING: - The 'docs' directory contains incomplete information.
		 It was left there in hopes of completing it one day.
		 
		 - The pulse width modulated sound expects a pull-up attached to its
		 output as it will enter a floating state when requiring a rise.

Requirements:
	iverilog 10.x
	board xdc file [for bitstream creation]
	
	must create the following directories to run simulations:
	- simdump
	- bin

Using the SD card:
    The SD card should be formatted into FAT32 / FAT16 format.
    The software handling the SD card cannot cope with fragmentation,
    therfore every time the contents are to be modified, I suggest formatting
    the SD card. Regarding to the contents, all binary images of tapes/disks
    are archived in a special .mmb file. There are perl scripts and tools able
    to create, add and remove contents of said archive. The .mmb file should be
    the only file on the SD card.

    Link to perl scripts (by Stephen Harris):
    https://github.com/sweharris/MMB_Utils

    You can find tape and disk images on the following website:
    https://www.stairwaytohell.com/bbc/index.html?page=sthcollection
---------------
END OF DOCUMENT
