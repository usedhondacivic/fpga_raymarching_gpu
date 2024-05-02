				.include	"address_map_arm.s"

/* ********************************************************************************
 * This program demonstrates the use of parallel ports in the DE1-SoC Computer
 * It performs the following: 
 * 	1. displays the SW switch values on the red lights LEDR
 * 	2. displays a rotating pattern on the HEX displays
 * 	3. if KEY[3..0] is pressed, uses the SW switches as the pattern
 ********************************************************************************/
				.text									// executable code follows
				.global	_start
_start:		
				MOV		R0, #31					// used to rotate a bit pattern: 31 positions to the
														// right is equivalent to 1 position to the left
				LDR		R1, =LEDR_BASE			// base address of LEDR lights
				LDR		R2, =HEX3_HEX0_BASE	// base address of HEX3_HEX0 7-segs
				LDR		R3, =SW_BASE			// base address of SW switches
				LDR		R4, =KEY_BASE			// base address of KEY pushbuttons
				LDR		R5, HEX_bits

DO_DISPLAY:	LDR		R6, [R3]					// load SW switches
				STR		R6, [R1]					// write to red LEDs

				LDR		R7, [R4]					// load pushbutton keys
				CMP		R7, #0					// check if any key is presssed
				BEQ		NO_BUTTON
				MOV		R5, R6					// copy SW switch values onto HEX displays
WAIT:
				LDR		R7, [R4]					// load pushbuttons
				CMP		R7, #0
				BNE		WAIT 						// wait for button release

NO_BUTTON:	STR		R5, [R2]					// store to HEX3 ... HEX0
				ROR		R5, R0					// rotate the displayed pattern to the left

				LDR		R6, =50000000			// delay counter
SUB_LOOP:	SUBS		R6, R6, #1
				BNE		SUB_LOOP

				B 			DO_DISPLAY

HEX_bits:	.word		0x0000000F				// initial pattern for the HEX displays

				.end    

