#include "globals.h"

extern volatile int buf_index_record;
extern volatile int buf_index_play;

/***************************************************************************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This ISR checks which KEY has been pressed. If KEY1, then it enables audio-in
 * interrupts (recording). If KEY2, it enables audio-out interrupts (playback).
****************************************************************************************/
void pushbutton_ISR(struct alt_up_dev *up_dev, unsigned int id)
{
	alt_up_audio_dev *audio_dev;

	audio_dev = up_dev->audio_dev;
	
	int KEY_value;

	/* read the pushbutton interrupt register */
	KEY_value = IORD_ALTERA_AVALON_PIO_EDGE_CAP(PUSHBUTTONS_BASE);
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(PUSHBUTTONS_BASE, 0xE);  	// Clear the interrupt

	if (KEY_value == 0x2)										// check KEY1
	{
		// reset the buffer index for recording
		buf_index_record = 0;
		// clear audio FIFOs
		alt_up_audio_reset_audio_core (audio_dev);
		// enable audio-in interrupts
		alt_up_audio_enable_read_interrupt (audio_dev);
	}
	else if (KEY_value == 0x4)									// check KEY2
	{
		// reset counter to start playback
		buf_index_play = 0;
		// clear audio FIFOs
		alt_up_audio_reset_audio_core (audio_dev);
		// enable audio-out interrupts
		alt_up_audio_enable_write_interrupt (audio_dev);
	}
	return;
}
