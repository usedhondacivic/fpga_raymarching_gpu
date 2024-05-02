#include "address_map_arm.h"
#include "JTAG_UART.h"

/********************************************************************************
 * Subroutine to send a character to the JTAG UART
********************************************************************************/
void put_jtag( char c )
{
	volatile int * JTAG_UART_ptr 	= (int *) JTAG_UART_BASE;	// JTAG UART address

	int control;
	control = *(JTAG_UART_ptr + 1);		// read the JTAG_UART control register
	if (control & 0xFFFF0000)				// if space, echo character, else ignore 
		*(JTAG_UART_ptr) = c;
}

/********************************************************************************
 * Subroutine to read a character from the JTAG UART
 * Returns \0 if no character, otherwise returns the character
********************************************************************************/
char get_jtag( void )
{
	volatile int * JTAG_UART_ptr 	= (int *) JTAG_UART_BASE;	// JTAG UART address

	int data;
	data = *(JTAG_UART_ptr);		 		// read the JTAG_UART data register
	if (data & 0x00008000)					// check RVALID to see if there is new data
		return ((char) data & 0xFF);
	else
		return ('\0');
}
