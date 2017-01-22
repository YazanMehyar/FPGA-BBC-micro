#include <stdint.h>
#include <vpi_user.h>
#include "6502_csim.c"

#define KiB64 65536
static uint8_t mem[KiB64];

uint8_t
read6502(uint16_t address){
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

    vpi_free_object(args_iter);
	return mem[addr];
}

int
run_step(char *data) {
	step6502();
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
    s_vpi_systf_data tf_data[4] = {
        {.type=vpiSysTask,.tfname="$write_mem",.calltf=write_mem,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$read_mem",.calltf=read_mem,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$reset_6502",.calltf=reset_6502,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$run_step",.calltf=run_step,.sizetf=0,.user_data=0}
    };

	for(uint8_t i = 0; i < 4; i++){
		vpi_register_systf(&tf_data[i]);
	}
}

void (*vlog_startup_routines[])() = {
    mos6502_register,
    NULL
};

// END OF DOCUMENT
