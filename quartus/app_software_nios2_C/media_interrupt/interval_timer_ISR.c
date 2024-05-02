#include "address_map_nios2.h"

extern volatile int timeout;
/*****************************************************************************
 * Interval timer interrupt service routine
 *                                                                          
 * Controls refresh of the VGA screen
 * 
******************************************************************************/
void interval_timer_ISR( )
{
	volatile int * interval_timer_ptr = (int *) TIMER_BASE;

	*(interval_timer_ptr) = 0; 										// clear the interrupt
	timeout = 1;															// set global variable
    
	return;
}

