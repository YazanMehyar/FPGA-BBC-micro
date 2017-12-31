#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/shm.h>
#include <signal.h>
#include <string.h>
#include <stdint.h>
#include <vpi_user.h>

#define KEY     123

static uint32_t PIXELS;
static uint32_t LINES;
static uint32_t pixel_pos = 0;

/******************************************************************************/
// C helper functions

static void
set_pixel(uint32_t colour){

	int shmid;
	char *shm, *hndshk;
	uint32_t SHMSZ = PIXELS*LINES+1;

	if (pixel_pos > SHMSZ - 2) return;

	/* locate the shared memory buffer that is used as frame store */
	if ((shmid = shmget((key_t) KEY, SHMSZ, 0666)) < 0) {
		vpi_printf("virtualScreen: ERROR - cannot locate shared memory.\n");
		exit(EXIT_FAILURE);
	}

	/* attach the segment to local data space */
	if ((shm = (char *) shmat(shmid, NULL, 0)) == (char *) -1) {
		vpi_printf("virtualScreen: ERROR - cannot attach shared memory.\n");
		exit(EXIT_FAILURE);
	}

	hndshk = shm + (SHMSZ-1);
	shm[pixel_pos++] = colour;
	*hndshk = 1;
	shmdt(shm);

	// Don't cross to another line until a H_SYNC comes
	if(pixel_pos % PIXELS == 0) pixel_pos--;
}

static void
screen_reset(void){
	pixel_pos = 0;
}

static void
next_line(void){
	pixel_pos+= PIXELS - pixel_pos%PIXELS;
}


/******************************************************************************/
// VPI system functions
int start_screen() {
    pid_t scrPid;

    /* vpi get argument */

	vpiHandle args_iter;
	struct t_vpi_value argval;

	args_iter = vpi_iterate(vpiArgument, vpi_handle(vpiSysTfCall, NULL));
	argval.format = vpiIntVal;
	vpi_get_value(vpi_scan(args_iter), &argval);
	PIXELS = (uint32_t) argval.value.integer;
	vpi_get_value(vpi_scan(args_iter), &argval);
	LINES  = (uint32_t) argval.value.integer;
	vpi_free_object(args_iter);

	/* vpi get argument */
	uint32_t SHMSZ = PIXELS*LINES+1;

    if ((shmget((key_t) KEY, SHMSZ, 0666)) >= 0) {
        vpi_printf("vscreen already running\n");
        exit(EXIT_SUCCESS);
    }

    scrPid = fork();
    if (scrPid == -1) {
        vpi_printf("caller: ERROR - cannot start screen.\n");
        exit(EXIT_FAILURE);
    } else if (scrPid == 0) {
        nice(10);
        char swidth[7];
        char sheight[7];

        sprintf(swidth,"-w%d",PIXELS);
        sprintf(sheight,"-h%d",LINES);

        static char *screen_args[7];
        screen_args[0] = "vscreen";
        screen_args[1] = "-c332";
        screen_args[2] = "-k123";
        screen_args[3] = "-s2";
        screen_args[4] = swidth;
        screen_args[5] = sheight;
        screen_args[6] = (char*) NULL;
        if (execvp("vscreen", screen_args)) {
            vpi_printf("caller: ERROR - cannot start vscreen.\n");
            exit(EXIT_FAILURE);
        }
    }

    while(shmget((key_t) KEY, SHMSZ, 0666) < 0);
    pixel_pos = 0;

    return 0;
}

int pixel_scan() {

	uint32_t colour;

	/* vpi get argument */

	vpiHandle args_iter;
	struct t_vpi_value argval;

	args_iter = vpi_iterate(vpiArgument, vpi_handle(vpiSysTfCall, NULL));
	argval.format = vpiIntVal;
	vpi_get_value(vpi_scan(args_iter), &argval);
	colour = (uint32_t) argval.value.integer;
	vpi_free_object(args_iter);

	/* vpi get argument */

	set_pixel(colour);

	return 0;
}

int iv_sync() {

	static uint8_t field;
	screen_reset();
	if(field) next_line();

	field = !field;
	return 0;
}

int ih_sync(){ next_line(); next_line(); return 0;}
int v_sync (){ screen_reset(); return 0;}
int h_sync (){ next_line();    return 0;}

/******************************************************************************/
// VPI hooks

void
top_register(void){
    s_vpi_systf_data tf_data[] = {
		{.type=vpiSysTask,.tfname="$start_screen",.calltf=start_screen,.sizetf=0,.user_data=0},
        {.type=vpiSysTask,.tfname="$pixel_scan",.calltf=pixel_scan,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$v_sync",.calltf=v_sync,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$h_sync",.calltf=h_sync,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$ih_sync",.calltf=ih_sync,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$iv_sync",.calltf=iv_sync,.sizetf=0,.user_data=0}
    };

	for(uint8_t i = 0; i < 6; i++){
		vpi_register_systf(&tf_data[i]);
	}
}

void (*vlog_startup_routines[])(void) = {
    top_register,
    NULL
};

// END OF DOCUMENT
