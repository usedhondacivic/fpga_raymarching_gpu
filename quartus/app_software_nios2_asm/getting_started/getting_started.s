	.include "address_map_nios2.s"
/********************************************************************************
 * This program demonstrates use of parallel ports in the DE1-SoC Computer
 *
 * It performs the following: 
 * 	1. displays the SW switch values on the red LEDR
 * 	2. displays a rotating pattern on the HEX displays
 * 	3. if KEY[3..0] is pressed, uses the SW switches as the pattern
********************************************************************************/
	.text									/* executable code follows */
	.global	_start
_start:

	/* initialize base addresses of parallel ports */
	movia		r15, SW_BASE		/* SW slider switch base address */
	movia		r16, LEDR_BASE		/* red LED base address */
	movia		r17, KEY_BASE		/* pushbutton KEY base address */
	movia		r19, HEX3_HEX0_BASE		/* HEX3_HEX0 base address */
	movia		r20, HEX5_HEX4_BASE		/* HEX7_HEX4 base address */
	movia		r18, HEX_bits
	ldw		r6, 0(r18)				/* load pattern for HEX displays */

DO_DISPLAY:
	ldwio		r4, 0(r15)				/* load slider switches */
	stwio		r4, 0(r16)				/* write to red LEDs */

	ldwio		r5, 0(r17)				/* load pushbuttons */
	beq		r5, r0, NO_BUTTON	
	mov		r6, r4					/* copy SW switch values onto HEX displays */
WAIT:
	ldwio		r5, 0(r17)				/* load pushbuttons */
	bne		r5, r0, WAIT			/* wait for button release */

NO_BUTTON:
	stwio		r6, 0(r19)				/* store to HEX3 ... HEX0 */
	stwio		r6, 0(r20) 				/* store to HEX7 ... HEX4 */
	roli		r6, r6, 1				/* rotate the displayed pattern */

	movia		r7, 1000000				/* delay counter */
DELAY:	
	subi		r7, r7, 1
	bne		r7, r0, DELAY	

	br 		DO_DISPLAY

/********************************************************************************/
	.data									/* data follows */

HEX_bits:
	.word 0x0000000F

