#include "system.h"
#include "altera_avalon_pio_regs.h"

/* This program demonstrates use of parallel ports in the DE2-115 board
 *
 * It performs the following: 
 * 	1. displays the SW switch values on the red LEDR
 * 	2. displays the KEY[3..1] pushbutton values on the green LEDG
 * 	3. displays a rotating pattern on the HEX displays
 * 	4. if KEY[3..1] is pressed, uses the SW switches as the pattern
*/

int main(void)
{
    /* The base addresses of devices are listed in the "BSP/system.h" file*/
    
	int HEX_bits = 0x0000000F;					// pattern for HEX displays
	int SW_value, KEY_value;
	volatile int delay_count;					// volatile so the C compiler doesn't remove the loop

	while(1)
	{
		SW_value = IORD_ALTERA_AVALON_PIO_DATA(SLIDER_SWITCHES_BASE);	// read the SW slider switch values
        IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE , SW_value);		// light up the red LEDs

		KEY_value = IORD_ALTERA_AVALON_PIO_DATA(PUSHBUTTONS_BASE); 		// read the pushbutton KEY values
        
		if (KEY_value != 0)						// check if any KEY was pressed
		{
			HEX_bits = SW_value;					// set pattern using SW values
			while (IORD_ALTERA_AVALON_PIO_DATA(PUSHBUTTONS_BASE));						// wait for pushbutton KEY release
		}
        
		IOWR_ALTERA_AVALON_PIO_DATA(HEX3_HEX0_BASE , HEX_bits);	// display pattern on HEX3 ... HEX0
		IOWR_ALTERA_AVALON_PIO_DATA(HEX5_HEX4_BASE , HEX_bits);			// display pattern on HEX7 ... HEX4

		/* rotate the pattern shown on the HEX displays */
		if (HEX_bits & 0x80000000)
			HEX_bits = (HEX_bits << 1) | 1;
		else
			HEX_bits = HEX_bits << 1;

		for (delay_count = 100000; delay_count != 0; --delay_count); // delay loop
	}
    return 0;
}
