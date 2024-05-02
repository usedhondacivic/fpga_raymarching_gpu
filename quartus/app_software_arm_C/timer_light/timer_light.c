#include "address_map_arm.h"

#define bit_24_pattern 0x01000000

/* This program provides a simple example of code for the ARM A9. The program performs 
 * the following: 
 * 	1. starts the ARM A9 private timer
 * 	2. loops indefinitely, toggling the green light LEDG when the timer expires
*/
int main(void)
{
	/* Declare volatile pointers to I/O registers (volatile means that the locations
	 * will not be cached, even in registers) */
	volatile int * HPS_GPIO1_ptr 					= (int *) HPS_GPIO1_BASE;
	volatile int * MPcore_private_timer_ptr	= (int *) MPCORE_PRIV_TIMER;
	
	int HPS_LEDG = bit_24_pattern;				// value to turn on the HPS green light LEDG
	int counter = 200000000;						// timeout = 1/(200 MHz) x 200x10^6 = 1 sec

	*(HPS_GPIO1_ptr + 1) = bit_24_pattern;		// write to the data direction register to set
															// bit 24 (LEDG) of GPIO1 to be an output
	*(MPcore_private_timer_ptr) = counter;		// write to timer load register
	*(MPcore_private_timer_ptr + 2) = 0b011;	// mode = 1 (auto), enable = 1

	while(1)
	{
		*HPS_GPIO1_ptr = HPS_LEDG;								// turn on/off LEDG
		while (*(MPcore_private_timer_ptr + 3) == 0)
			;															// wait for timer to expire
		*(MPcore_private_timer_ptr + 3) = 1; 				// reset timer flag bit
		HPS_LEDG ^= bit_24_pattern;							// toggle bit that controls LEDG
	}
}
