#include "address_map_arm.h"
extern volatile int buffer_index;

/***************************************************************************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * Enables audio record or playback interrupts
****************************************************************************************/
void pushbutton_ISR( void )
{
	volatile int * KEY_ptr = (int *) KEY_BASE;		// pushbutton keys base address
	volatile int * audio_ptr = (int *) AUDIO_BASE;	// audio port base address
	
	int KEY_value;

	KEY_value = *(KEY_ptr + 3);			// read the pushbutton interrupt register
	*(KEY_ptr + 3) = KEY_value;			// clear the interrupt

	if (KEY_value == 0x1)					// check KEY0
	{
		// reset the buffer index for recording
		buffer_index = 0;
		// clear audio-in FIFO
		*(audio_ptr) = 0x4;
		// turn off clear, and enable audio-in interrupts
		*(audio_ptr) = 0x1;
	}
	else if (KEY_value == 0x2)				// check KEY1
	{
		// reset counter to start playback
		buffer_index = 0;
		// clear audio-out FIFO
		*(audio_ptr) = 0x8;
		// turn off clear, and enable audio-out interrupts
		*(audio_ptr) = 0x2;
	}
	return;
}
