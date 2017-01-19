#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#define KiB64 65536
#define RESET_VEC (uint16_t) 0xFFFC
#define bin_dir "/home/zen/FinalYearProject/Software/test_bin"

extern void reset6502();
extern void step6502();

extern uint16_t pc;
extern uint8_t sp, a, x, y, status;

static uint8_t mem[KiB64];
static bool stop = false;

uint8_t
read6502(uint16_t address){
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

	sprintf(sbuffer, bin_dir"/%s", file_name);
	FILE *f = fopen(sbuffer,"r");
	i = 0;
	while ((c = fgetc(f)) != EOF && i < KiB64) mem[i++] = c;
}

char *day[] = {"Sun", "Mon", "Teus", "Wed", "Thur", "Fri", "Sat"};

void
print_results(void){
	uint16_t list = 0x0c00;
	for (uint8_t i = 0; i < 8; i++) {
		printf("%d: %hhx\n", i, mem[list + i]);
	}
}

int
main(int argc, char const *argv[]) {
	while (--argc) {
		read_mem_file(argv[argc]);
		reset6502();
		printf("Reset Vector $%02hhX%02hhX\n", mem[RESET_VEC+1], mem[RESET_VEC]);
		while (!stop){
			step6502();
		}
		// printf("Day is %s\n", day[a]);
		print_results();
		stop = false;
	}
	return 0;
}
