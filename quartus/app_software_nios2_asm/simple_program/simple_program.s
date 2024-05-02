.text
.equ	LEDs,  0xFF200000
.equ	SWITCHES, 0xFF200040
.global _start

_start:
	movia	r2, LEDs		/* Address of red LEDs. */         
	movia	r3, SWITCHES	/* Address of switches. */
LOOP:
	ldwio	r4, (r3)		/* Read the state of switches.*/
	stwio	r4, (r2)		/* Display the state on LEDs. */
	br	LOOP
.end