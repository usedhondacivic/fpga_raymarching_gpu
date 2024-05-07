#include "fp_27.h"
#include "math.h"
#include "stdio.h"

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

// https://stackoverflow.com/questions/49139283/are-there-any-numbers-that-enable-fast-modulo-calculation-on-floats
unsigned int power_of_two_mod(unsigned int fp_rep, int E)
{
	// Bits [25:18] = exponent
	char exp = fp_rep >> 18 & 0xFF;
	unsigned int exp_dif = (exp - 127) - E;
	unsigned int bits_to_keep = 18 - exp_dif;
}

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
	return 0;
}
