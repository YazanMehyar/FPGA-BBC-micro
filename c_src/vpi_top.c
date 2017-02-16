#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/shm.h>
#include <signal.h>
#include <string.h>
#include <stdint.h>
#include <vpi_user.h>

#define PIXELS  640 /* screen width  */
#define LINES   480 /* screen height */
#define SHMSZ   (PIXELS*LINES)+1 /* size of the shared memory buffer */
#define KEY     123

static char *screen_args[] = {"vscreen", "-c332", "-k123", "-s2", NULL};
static uint32_t pixel_pos = 0;
/******************************************************************************/
// C helper functions


static void
set_pixel(uint32_t colour){

	int shmid;
	char *shm, *hndshk;

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

	if (pixel_pos > SHMSZ-2) {
        vpi_printf("virtual screen memory out of range address is %d.\n", pixel_pos);
        exit(EXIT_FAILURE);
    }

	hndshk = shm + (SHMSZ-1);
	shm[pixel_pos++] = colour;
	*hndshk = 1;

	shmdt(shm);

}

static void
screen_reset(void){
	pixel_pos = 0;
}

static void
next_line(void){
	// let integer division do the job
	pixel_pos = ((pixel_pos + PIXELS) / PIXELS) * PIXELS;
}


/******************************************************************************/
// VPI system functions
int
start_screen(char *data) {
    pid_t scrPid;

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
        if (execvp("vscreen", screen_args)) {
            vpi_printf("caller: ERROR - cannot start vscreen.\n");
            exit(EXIT_FAILURE);
        }
    }

    while(shmget((key_t) KEY, SHMSZ, 0666) < 0);

    return 0;
}

int
pixel_scan(char *data) {

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

int v_sync(char *data){ screen_reset(); }
int h_sync(char *data){ next_line(); }

/******************************************************************************/
// VPI hooks

void
top_register(void){
    s_vpi_systf_data tf_data[] = {
		{.type=vpiSysTask,.tfname="$start_screen",.calltf=start_screen,.sizetf=0,.user_data=0},
        {.type=vpiSysTask,.tfname="$pixel_scan",.calltf=pixel_scan,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$v_sync",.calltf=v_sync,.sizetf=0,.user_data=0},
		{.type=vpiSysTask,.tfname="$h_sync",.calltf=h_sync,.sizetf=0,.user_data=0}
    };

	for(uint8_t i = 0; i < sizeof(tf_data); i++){
		vpi_register_systf(&tf_data[i]);
	}
}

void (*vlog_startup_routines[])() = {
    top_register,
    NULL
};

// END OF DOCUMENT
