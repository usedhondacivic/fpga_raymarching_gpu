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
	printf("640: %x\n480: %x\n30: %x\n1.5: %x\n2: %x\n0.2: %x\n0.0: %x\n",
		   floatToReg27(640.0),
		   floatToReg27(480.0),
		   floatToReg27(30.0),
		   floatToReg27(1.3),
		   floatToReg27(2.0),
		   floatToReg27(0.2),
		   floatToReg27(0.0));

	printf("1 / SQRT 3: %x\n", floatToReg27(1 / sqrtf(3.0)));
	printf("-1: %x\n", floatToReg27(-1.0));
	printf("3: %x\n", floatToReg27(3.0));
	printf("-0.1: %x\n", floatToReg27(-0.1));
	printf("1.0: %x\n", floatToReg27(1.0));
	printf("50.0: %x\n", floatToReg27(50.0));
	printf("0.5: %x\n", floatToReg27(0.5));
	return 0;
}
