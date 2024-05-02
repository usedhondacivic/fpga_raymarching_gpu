          .include "address_map_arm.s"

          .text
          .global _start
_start:
	       LDR     R1, =LEDR_BASE  /* Address of red LEDs. */         
          LDR     R2, =SW_BASE    /* Address of switches. */
LOOP:     LDR     R3, [R2]        /* Read the state of switches.*/
          STR     R3, [R1]        /* Display the state on LEDs. */
          B       LOOP
.end
