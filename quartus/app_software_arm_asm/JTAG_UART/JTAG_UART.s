				.include "address_map_arm.s"
/********************************************************************************
 * This program demonstrates use of the JTAG UART port in the DE1-SoC Computer
 * It performs the following: 
 *   1. sends an example text string to the JTAG UART
 *   2. reads and echos character data from/to the JTAG UART
********************************************************************************/
				.text									/* executable code follows */
				.global	_start
_start:
				/* set up stack pointer */
				MOV		SP, #DDR_END - 3	// highest memory word address

				/* print a text string */
				LDR		R4, =TEXT_STRING
LOOP:
				LDRB		R0, [R4]
				CMP		R0, #0
				BEQ		CONT						// string is null-terminated

				BL			PUT_JTAG					// send the character in R0 to UART
				ADD		R4, R4, #1
				B			LOOP

				/* read and echo characters */
CONT:			BL			GET_JTAG					// read from the JTAG UART
				CMP		R0, #0					// check if a character was read
				BEQ		CONT
				BL			PUT_JTAG
				B			CONT

/********************************************************************************
 * Subroutine to send a character to the JTAG UART
 *		R0	= character to send
********************************************************************************/
				.global	PUT_JTAG
PUT_JTAG:
				LDR		R1, =JTAG_UART_BASE	// JTAG UART base address 
   			LDR		R2, [R1, #4]			// read the JTAG UART control register
				LDR		R3, =0xFFFF
   			ANDS		R2, R2, R3				// check for write space
   			BEQ		END_PUT					// if no space, ignore the character
   			STR		R0, [R1]					// send the character
END_PUT:
				BX			LR

/********************************************************************************
 * Subroutine to get a character from the JTAG UART
 *		returns the character read in R0
********************************************************************************/
				.global	GET_JTAG
GET_JTAG:
				LDR		R1, =JTAG_UART_BASE	// JTAG UART base address 
   			LDR		R0, [R1]					// read the JTAG UART data register
   			ANDS		R2, R0, #0x8000		// check if there is new data
   			BEQ		RET_NULL					// if no data, return 0
   			AND		R0, R0, #0x00FF		// return the character
				B			END_GET
RET_NULL:	MOV		R0, #0
END_GET:		BX			LR

TEXT_STRING:
				.asciz	"\nJTAG UART example code\n> "
				.end
