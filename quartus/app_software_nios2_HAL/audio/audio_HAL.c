#include "system.h"
#include "altera_up_avalon_audio.h"
#include "sys/alt_stdio.h"
#include "altera_avalon_pio_regs.h"

/* globals */
#define BUF_SIZE 500000			// about 10 seconds of buffer (@ 48K samples/sec)
#define BUF_THRESHOLD 96		// 75% of 128 word buffer

/* function prototypes */
void check_KEYs( int *, int *, int *, alt_up_audio_dev * );

/********************************************************************************
 * This program demonstrates use of HAL functions
 *
 * It performs the following: 
 *  1. records audio for about 10 seconds when KEY[1] is pressed. LEDR[0] is
 * 	   lit while recording
 * 	2. plays the recorded audio when KEY[2] is pressed. LEDR[1] is lit while 
 * 	   playing
********************************************************************************/
int main(void)
{
    /* The base addresses of devices are listed in the "BSP/system.h" file*/

	/* declare variables to point to devices that are opened */
	alt_up_audio_dev *audio_dev;

	audio_dev = alt_up_audio_open_dev ("/dev/Audio_Subsystem_Audio");
	if ( audio_dev == NULL)
	{
		alt_printf ("Error: could not open audio device\n");
		return -1;
	}
	else
		alt_printf ("Opened audio device\n");

	/* used for audio record/playback */
	int record = 0, play = 0, buffer_index = 0;
	unsigned int l_buf[BUF_SIZE];
	unsigned int r_buf[BUF_SIZE];
	int num_read; int num_written;
	/* read and echo audio data */
	record = 0;
	play = 0;
	while(1)
	{
		check_KEYs ( &record, &play, &buffer_index, audio_dev );
		if (record)
		{
			IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE , 0x1); // set LEDR[0] on
            
			// record data until the buffer is full
			if (buffer_index < BUF_SIZE)
			{
				num_read = alt_up_audio_record_r (audio_dev, &(r_buf[buffer_index]), 
					BUF_SIZE - buffer_index);
				/* assume we can read same # words from the left and right */
				(void) alt_up_audio_record_l (audio_dev, &(l_buf[buffer_index]), 
					num_read);
				buffer_index += num_read;

				if (buffer_index == BUF_SIZE)
				{
					// done recording
					record = 0;
					IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE , 0x0); // set LEDR off
				}
			}
		}
		else if (play)
		{
			IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE , 0x2); // set LEDR[1] on

			// output data until the buffer is empty 
			if (buffer_index < BUF_SIZE)
			{
				num_written = alt_up_audio_play_r (audio_dev, &(r_buf[buffer_index]), 
				 	BUF_SIZE - buffer_index);
				/* assume that we can write the same # words to the left and right */
				(void) alt_up_audio_play_l (audio_dev, &(l_buf[buffer_index]), 
					num_written);
				buffer_index += num_written;

				if (buffer_index == BUF_SIZE)
				{
					// done playback
					play = 0;
					IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE , 0x0); // set LEDR off
				}
			}
		}
	}
}

/****************************************************************************************
 * Subroutine to read KEYs
****************************************************************************************/
void check_KEYs(int *KEY1, int *KEY2, int *counter,
					 alt_up_audio_dev *audio_dev)
{
	int KEY_value;

	KEY_value = IORD_ALTERA_AVALON_PIO_DATA(PUSHBUTTONS_BASE); // read the pushbutton KEY values
	while (IORD_ALTERA_AVALON_PIO_DATA(PUSHBUTTONS_BASE));		// wait for pushbutton KEY release

	if (KEY_value == 0x2)					// check KEY1
	{
		// reset counter to start recording
		*counter = 0;
		// reset audio port
		alt_up_audio_reset_audio_core (audio_dev);

		*KEY1 = 1;
	}
	else if (KEY_value == 0x4)				// check KEY2
	{
		// reset counter to start playback
		*counter = 0;
		// reset audio port
		alt_up_audio_reset_audio_core (audio_dev);

		*KEY2 = 1;
	}
}
