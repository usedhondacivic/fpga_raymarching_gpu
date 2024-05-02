#include "address_map_arm.h"
extern volatile int timeout;

/*****************************************************************************
 * MPcore private timer interrupt service routine
 *                                                                          
 * Controls refresh of the VGA screen
******************************************************************************/
void MPcore_private_timer_ISR( )
{
	volatile int * MPcore_private_timer_ptr = (int *) MPCORE_PRIV_TIMER;	// private timer address

	*(MPcore_private_timer_ptr + 3) = 1;	// Write to timer interrupt status register to
														// clear the interrupt (note: not really necessary)

	timeout = 1;									// set global variable

	return;
}

