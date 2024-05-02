			.include	"address_map_arm.s"
			.equ		bit_24_pattern, 0x01000000
/* This program provides a simple example of code for the ARM A9. The program performs 
 * the following: 
 * 	1. starts the ARM A9 private timer
 * 	2. loops forever, toggling the HPS green light LEDG when the timer expires
*/
			.text
			.global	_start
_start:		
			LDR 		R0, =HPS_GPIO1_BASE			// GPIO1 base address
			LDR 		R1, =MPCORE_PRIV_TIMER		// MPCore private timer base address

			LDR		R2, =bit_24_pattern			// value to turn on the HPS green light LEDG
			STR		R2, [R0, #0x4]					// write to the data direction register to set
															// bit 24 (LEDG) of GPIO1 to be an output
			LDR		R3, =200000000					// timeout = 1/(200 MHz) x 200x10^6 = 1 sec
			STR		R3, [R1]							// write to timer load register
			MOV		R3, #0b011						// set bits: mode = 1 (auto), enable = 1
			STR		R3, [R1, #0x8]					// write to timer control register
LOOP:
			STR		R2, [R0]							// turn on/off LEDG
WAIT:		LDR		R3, [R1, #0xC]					// read timer status
			CMP		R3, #0
			BEQ		WAIT								// wait for timer to expire

			STR		R3, [R1, #0xC]					// reset timer flag bit
			EOR		R2, R2, #bit_24_pattern		// toggle LEDG value
			B 			LOOP

			.end   
