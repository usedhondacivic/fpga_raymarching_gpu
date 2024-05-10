#pragma once
#include "math.h"

// Convert a C floating point into a 27-bit register floating point.
inline unsigned int floatToReg27(float f)
{
	int f_f = (*(int *)&f);
	int f_sign = (f_f >> 31) & 0x1;
	int f_exp = (f_f >> 23) & 0xFF;
	int f_frac = f_f & 0x007FFFFF;
	int r_sign;
	int r_exp;
	int r_frac;
	r_sign = f_sign;
	if ((f_exp == 0x00) || (f_exp == 0xFF)) {
		// 0x00 -> 0 or subnormal
		// 0xFF -> infinity or NaN
		r_exp = 0;
		r_frac = 0;
	} else {
		r_exp = (f_exp) & 0xFF;
		r_frac = ((f_frac >> 5)) & 0x0003FFFF;
	}
	return (r_sign << 26) | (r_exp << 18) | r_frac;
}

// Convert a 27-bit register floating point into a C floating point.
inline float reg27ToFloat(unsigned int r)
{
	int sign = (r & 0x04000000) >> 26;
	unsigned int exp = (r & 0x03FC0000) >> 18;
	int frac = (r & 0x0003FFFF);
	float result = pow(2.0, (float)(exp - 127.0));
	result = (1.0 + (((float)frac) / 262144.0)) * result;
	if (sign)
		result = result * (-1);
	return result;
}
