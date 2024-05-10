///////////////////////////////////////
// g++ main.c -o raymarcher -lm
///////////////////////////////////////

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#include "fp_27.h"
#include "linmath.h"

#include <math.h>

#include <time.h>

#include "noise.h"

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
#define RED_SHIFT 0x120
#define GREEN_SHIFT 0x130
#define BLUE_SHIFT 0x140
#define FOG_SHIFT 0x150
#define COLOR_ENABLES 0x160

volatile unsigned int *lookat_1_1, *lookat_1_2, *lookat_1_3;
volatile unsigned int *lookat_2_1, *lookat_2_2, *lookat_2_3;
volatile unsigned int *lookat_3_1, *lookat_3_2, *lookat_3_3;
volatile unsigned int *eye_x, *eye_y, *eye_z;
volatile unsigned int *red_shift, *green_shift, *blue_shift, *fog_shift;
volatile unsigned int *color_enables;

vec3 up = { 0.0, 1.0, 0.0 };
void set_uniforms(vec3 eye, vec3 target)
{

	*eye_x = floatToReg27(eye[0]);
	*eye_y = floatToReg27(eye[1]);
	*eye_z = floatToReg27(eye[2]);

	vec3 neg_eye;
	vec3_scale(neg_eye, eye, -1.0);
	vec3 target_minus_eye;
	vec3_add(target_minus_eye, target, neg_eye);
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

int frame_count=0;
vec3 eye = { -5.0, -5.0, -5.0 };
vec3 target = { -4.0, -5.0, -5.0 };
float yaw, pitch, roll;

// Create and configure noise state
OSN::Noise<2> noise;
vec3 velocity = {1.0, 0.0, 0.0};
void fly_random(float move_speed, float turn_speed, float rate_of_change){
	float counter = frame_count * rate_of_change + 2000.0;
	vec3 main_axis;
	vec3_dup(main_axis, up);
	vec3 cross_axis;
	vec3_mul_cross(cross_axis, velocity, up);		
	vec3_norm(cross_axis, cross_axis);
	vec3_norm(main_axis, main_axis);
	vec3_scale(cross_axis, cross_axis, noise.eval(counter, counter) * turn_speed);
	vec3_scale(main_axis, main_axis, noise.eval((float)(counter+200.0), counter) * turn_speed);
	vec3_add(velocity, velocity, cross_axis);
	vec3_add(velocity, velocity, main_axis);
	vec3_norm(velocity, velocity);
	if(velocity[1] >  0.75 )
		velocity[1] = 0.75;
	if(velocity[1] <  -0.75 )
		velocity[1] = -0.75;
	vec3_scale(velocity, velocity, move_speed);
	vec3_add(target, target, velocity);	
	// printf("target: x: %f, y: %f, z: %f\n", target[0], target[1], target[2]);
	// printf("eye: x: %f, y: %f, z: %f\n", eye[0], eye[1], eye[2]);
	vec3_norm(velocity, velocity);
	vec3_scale(velocity, velocity, 2.0);
	// printf("vel: x: %f, y: %f, z: %f\n", velocity[0], velocity[1], velocity[2]);
	vec3_add(eye, target, velocity);
	set_uniforms(eye, target);
};

void orbit(float distance, float sway){
	target[0] = 0.0;
	target[1] = 0.0;
	target[2] = 0.0;
	eye[0] = cos(frame_count * (M_PI / 225.0));
	eye[1] = sin(frame_count * (M_PI / 300.0));
	eye[2] = sin(frame_count * (M_PI / 150.0) + 1.0);
	vec3_norm(eye, eye);
	vec3_scale(eye, eye, sway * sin(frame_count * (M_PI / 350.0) + 1.7) + distance);
	set_uniforms(eye, target);
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
    
	red_shift=(unsigned int *)(h2p_lw_virtual_base + (( RED_SHIFT ) & ( HW_REGS_MASK ) ));
	green_shift=(unsigned int *)(h2p_lw_virtual_base + (( GREEN_SHIFT ) & ( HW_REGS_MASK ) ));
	blue_shift=(unsigned int *)(h2p_lw_virtual_base + (( BLUE_SHIFT ) & ( HW_REGS_MASK ) ));
	fog_shift=(unsigned int *)(h2p_lw_virtual_base + (( FOG_SHIFT ) & ( HW_REGS_MASK ) ));

	color_enables=(unsigned int *)(h2p_lw_virtual_base + (( COLOR_ENABLES ) & ( HW_REGS_MASK ) ));

	*red_shift = 4;
	*color_enables[0] = 1;
	*green_shift = 0;
	*color_enables[1] = 0;
	*blue_shift = 5;
	*color_enables[2] = 1;
	*fog_shift = 2;
	*color_enables[3] = 1;

    while(1){
		// orbit(20.0, 4.0);
		// set_uniforms(eye, target);
		fly_random(0.5, 0.01, 0.001);
        frame_count++;
        delay(20);
    }
    return 0;
}