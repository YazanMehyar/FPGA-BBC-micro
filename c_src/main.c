/**
* @Author: Yazan Mehyar <mbax4ym3>
* @Date:   Sat, 21 Jan 2017
* @Email:  yazan.mehyar@student.manchester.ac.uk
* @Last modified by:   zen
* @Last modified time: 24-Jan-2017
*/


#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#define KiB64 65536
#define RESET_VEC (uint16_t) 0xFFFC

extern void step6502(void);
extern void reset6502(void);

static uint8_t mem[KiB64];
static uint16_t fail_address = 0;
static bool stop = false;

uint8_t
read6502(uint16_t address){
	return mem[address];
}

uint8_t
fetch6502(uint16_t address){
	if(fail_address == address){
		printf("%s\n", "ERROR");
		stop = true;
	}
	fail_address = address;
	return mem[address];
}

void
write6502(uint16_t address, uint8_t value){
	mem[address] = value;
	if(address == RESET_VEC)
		stop = true;
}

static char sbuffer[127];

void
read_mem_file(char const *file_name){
	int c, i;

	FILE *f = fopen(file_name,"r");
	i = 0;
	while ((c = fgetc(f)) != EOF && i < KiB64) mem[i++] = c;
	fclose(f);
}

void
print_results(void){}

int
main(int argc, char const *argv[]) {
	while (--argc) {
		read_mem_file(argv[argc]);
		reset6502();

		printf("Reset Vector $%02hhX%02hhX\n", mem[RESET_VEC+1], mem[RESET_VEC]);

		while (!stop) { step6502(); }
		print_results();

		stop = false;
	}
	return 0;
}
