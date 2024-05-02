#include "address_map_arm.h"

/* This program demonstrates the use of parallel ports in the DE1-SoC Computer
 * It performs the following: 
 * 	1. displays the SW switch values on the red lights LEDR
 * 	2. displays a rotating pattern on the HEX displays
 * 	3. if a KEY[3..0] is pressed, uses the SW switches as the pattern
*/
int main(void)
{
	/* Declare volatile pointers to I/O registers (volatile means that the locations
	 * will not be cached, even in registers) */
	volatile int * LED_ptr 				= (int *) LEDR_BASE;
	volatile int * HEX3_HEX0_ptr		= (int *) HEX3_HEX0_BASE;
	volatile int * SW_switch_ptr		= (int *) SW_BASE;
	volatile int * KEY_ptr				= (int *) KEY_BASE;

	int HEX_bits = 0x0000000F;					// initial pattern for HEX displays
	int SW_value;
	volatile int delay_count;					// volatile so the C compiler doesn't remove the loop

	while (1)
	{
		SW_value = *(SW_switch_ptr);		 	// read the SW slider switch values
		*(LED_ptr) = SW_value; 					// light up the red LEDs

		if (*KEY_ptr != 0)						// check if any KEY was pressed
		{
			HEX_bits = SW_value;					// set pattern using SW values
			while (*KEY_ptr != 0);				// wait for pushbutton KEY release
		}
		*(HEX3_HEX0_ptr) = HEX_bits;			// display pattern on HEX3 ... HEX0

		/* rotate the pattern shown on the HEX displays */
		if (HEX_bits & 0x80000000)
			HEX_bits = (HEX_bits << 1) | 1;
		else
			HEX_bits = HEX_bits << 1;

		for (delay_count = 250000; delay_count != 0; --delay_count); // delay loop
	}
}
