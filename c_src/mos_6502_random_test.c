#include <stdint.h>
#include <vpi_user.h>
#include "6502_csim.c"

#define KiB64 65536
static uint8_t mem[KiB64];
static uint16_t last_read_addr;

uint8_t
read6502(uint16_t address){
	last_read_addr = address;
	return mem[address];
}

uint8_t
fetch6502(uint16_t address){
	return mem[address];
}

void
write6502(uint16_t address, uint8_t val){
	mem[address] = val;
}

/**************************************************************************************************/
// VPI system functions

int
write_mem(char *data) {
    uint16_t addr;
    uint8_t val;

    vpiHandle args_iter;
    struct t_vpi_value argval;

    args_iter = vpi_iterate(vpiArgument, vpi_handle(vpiSysTfCall, NULL));

    argval.format = vpiIntVal;
    vpi_get_value(vpi_scan(args_iter), &argval);
    addr = (uint16_t) argval.value.integer;
    vpi_get_value(vpi_scan(args_iter), &argval);
    val  = (uint8_t)  argval.value.integer;

	mem[addr] = val;

    vpi_free_object(args_iter);
	return 0;
}

int
read_mem(char *data) {
	uint16_t addr;

	vpiHandle args_iter;
    struct t_vpi_value argval;

    args_iter = vpi_iterate(vpiArgument, vpi_handle(vpiSysTfCall, NULL));

    argval.format = vpiIntVal;
    vpi_get_value(vpi_scan(args_iter), &argval);
    addr = (uint16_t) argval.value.integer;

	argval.value.integer = mem[addr];
	vpi_put_value(vpi_scan(args_iter), &argval, NULL, vpiNoDelay);

	vpi_free_object(args_iter);
	return 0;
}

int
run_step(char *data) {
	step6502();
	return 0;
}

int
get_internal_state(char *date){
	uint8_t reg_sel;
	uint8_t reg_val;

	vpiHandle args_iter;
    struct t_vpi_value argval;

    args_iter = vpi_iterate(vpiArgument, vpi_handle(vpiSysTfCall, NULL));

    argval.format = vpiIntVal;
    vpi_get_value(vpi_scan(args_iter), &argval);
    reg_sel = (uint8_t) argval.value.integer;


	switch (reg_sel) {
		case 0: reg_val = a; break;
		case 1: reg_val = x; break;
		case 2: reg_val = y; break;
		case 3: reg_val = sp; break;
		case 4: reg_val = status; break;
		case 5: reg_val = (uint8_t) pc; break;
		case 6: reg_val = (uint8_t) (pc >> 8); break;
		default: reg_val = 0xFF;
	}


	argval.value.integer = reg_val;
	vpi_put_value(vpi_scan(args_iter), &argval, NULL, vpiNoDelay);

	vpi_free_object(args_iter);
	return 0;
}

int
read_mem_cmd(char *data){
	vpi_printf("Last address read is %04hX\n", last_read_addr);
	vpi_printf("Memory @ addr is %02hX\n", mem[last_read_addr]);
	return 0;
}

int
reset_6502(char *data){
	reset6502();
	return 0;
}

/**************************************************************************************************/
// VPI hooks

void
mos6502_register(void){
    s_vpi_systf_data tf_data[] = {
        {.type=vpiSysTask,.tfname="$write_mem",.calltf=write_mem,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$read_mem",.calltf=read_mem,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$reset_6502",.calltf=reset_6502,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$run_step",.calltf=run_step,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$get_internal_state",.calltf=get_internal_state,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$read_mem_cmd",.calltf=read_mem_cmd,.sizetf=0,.user_data=0}
    };

	for(uint8_t i = 0; i < 6; i++){
		vpi_register_systf(&tf_data[i]);
	}
}

void (*vlog_startup_routines[])() = {
    mos6502_register,
    NULL
};

// END OF DOCUMENT
