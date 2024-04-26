#include "fp_27.h"
#include "math.h"
#include "stdio.h"

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

int main()
{
	// glsl float z = u_resolution.y / tan(radians(FIELD_OF_VIEW) / 2.0);
	float z = 1 / tan((M_PI / 2.0) / 2.0);
	printf("FOV of %f (rad)\nFloat value: %f\nHex constant: %x\n",
		   M_PI / 4.0,
		   z,
		   floatToReg27(z));
	printf("640: %x\n480: %x\n", floatToReg27(640.0), floatToReg27(480.0));
	return 0;
}
