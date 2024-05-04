///////////////////////////////////////
// gcc main.c -o raymarcher -lm
///////////////////////////////////////

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "fp_27.h"
#include "linmath.h"

#include <math.h>

#include <time.h>

void delay(int milli_seconds)
{
    // Storing start time
    clock_t start_time = clock();

    // looping till required time is not achieved
    while (clock() < start_time + (milli_seconds * CLOCKS_PER_SEC) / 1000)
        ;
}

// === FPGA side ===
#define HW_REGS_BASE ( 0xff200000 )
#define HW_REGS_SPAN ( 0x00200000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

#define LOOKAT_1_1_ADDR 0x00
#define LOOKAT_1_2_ADDR 0x10
#define LOOKAT_1_3_ADDR 0x20
#define LOOKAT_2_1_ADDR 0x30
#define LOOKAT_2_2_ADDR 0x40
#define LOOKAT_2_3_ADDR 0x50
#define LOOKAT_3_1_ADDR 0x60
#define LOOKAT_3_2_ADDR 0x70
#define LOOKAT_3_3_ADDR 0x80
#define EYE_X_ADDR 0x90
#define EYE_Y_ADDR 0x100
#define EYE_Z_ADDR 0x110

volatile unsigned int *lookat_1_1, *lookat_1_2, *lookat_1_3;
volatile unsigned int *lookat_2_1, *lookat_2_2, *lookat_2_3;
volatile unsigned int *lookat_3_1, *lookat_3_2, *lookat_3_3;
volatile unsigned int *eye_x, *eye_y, *eye_z;

void set_uniforms(vec3 eye)
{
	vec3 target = { 0.0, 0.0, 0.0 };
	vec3 up = { 0.0, 1.0, 0.0 };

	*eye_x = floatToReg27(eye[0]);
	*eye_y = floatToReg27(eye[1]);
	*eye_z = floatToReg27(eye[2]);

	vec3 neg_eye;
	vec3_scale(neg_eye, eye, -1.0);
	vec3 target_minus_eye;
	vec3_sub(target_minus_eye, target, neg_eye);
	vec3 z_axis;
	vec3_norm(z_axis, target_minus_eye);
	vec3 z_cross_up;
	vec3_mul_cross(z_cross_up, z_axis, up);
	vec3 x_axis;
	vec3_norm(x_axis, z_cross_up);
	vec3 y_axis;
	vec3_mul_cross(y_axis, z_axis, x_axis);

	// NOTE: glsl stores matricies in column major order (unlike row major, like
	// you're likely used to)
	*lookat_1_1 = floatToReg27(x_axis[0]);
	*lookat_2_1 = floatToReg27(x_axis[1]);
	*lookat_3_1 = floatToReg27(x_axis[2]);
	*lookat_1_2 = floatToReg27(y_axis[0]);
	*lookat_2_2 = floatToReg27(y_axis[1]);
	*lookat_3_2 = floatToReg27(y_axis[2]);
	*lookat_1_3 = floatToReg27(z_axis[0]);
	*lookat_2_3 = floatToReg27(z_axis[1]);
	*lookat_3_3 = floatToReg27(z_axis[2]);
}

int main(void)
{
    void *h2p_lw_virtual_base;
    int fd;
 
    // === get FPGA addresses ===
    // Open /dev/mem
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}
    
    // get virtual addr that maps to physical
	h2p_lw_virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );	
	if( h2p_lw_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return(1);
	}
    
	lookat_1_1=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_1_1_ADDR ) & ( HW_REGS_MASK ) ));
	lookat_1_2=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_1_2_ADDR ) & ( HW_REGS_MASK ) ));
	lookat_1_3=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_1_3_ADDR ) & ( HW_REGS_MASK ) ));
	lookat_2_1=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_2_1_ADDR ) & ( HW_REGS_MASK ) ));
	lookat_2_2=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_2_2_ADDR ) & ( HW_REGS_MASK ) ));
	lookat_2_3=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_2_3_ADDR ) & ( HW_REGS_MASK ) ));
	lookat_3_1=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_3_1_ADDR ) & ( HW_REGS_MASK ) ));
	lookat_3_2=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_3_2_ADDR ) & ( HW_REGS_MASK ) ));
	lookat_3_3=(unsigned int *)(h2p_lw_virtual_base + (( LOOKAT_3_3_ADDR ) & ( HW_REGS_MASK ) ));

	eye_x=(unsigned int *)(h2p_lw_virtual_base + (( EYE_X_ADDR ) & ( HW_REGS_MASK ) ));
	eye_y=(unsigned int *)(h2p_lw_virtual_base + (( EYE_Y_ADDR ) & ( HW_REGS_MASK ) ));
	eye_z=(unsigned int *)(h2p_lw_virtual_base + (( EYE_Z_ADDR ) & ( HW_REGS_MASK ) ));
    
	vec3 eye = { -5.0, -5.0, -5.0 };
    int frame_count=0;
    while(1){
        eye[0] = cos(frame_count * (M_PI / 225.0));
        eye[1] = sin(frame_count * (M_PI / 300.0));
        eye[2] = sin(frame_count * (M_PI / 150.0) + 1.0);
        vec3_norm(eye, eye);
        vec3_scale(eye, eye, 7.0);
        set_uniforms(eye);
        frame_count++;
        // printf("Write \n");
        delay(10);
    }
    return 0;
}