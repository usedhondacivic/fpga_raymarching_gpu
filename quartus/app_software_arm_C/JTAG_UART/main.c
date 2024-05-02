/* function prototypes */
void put_jtag(char);
char get_jtag(void);
/********************************************************************************
 * This program demonstrates use of the JTAG UART port in the DE0-SoC Computer
 * It performs the following: 
 *  	1. sends some example text strings to the JTAG UART
 * 	2. reads and echos character data from/to the JTAG UART
********************************************************************************/
int main(void)
{
	char text_string[] = "\nJTAG UART example code\n> \0";
	char *str, c;

	/* print a text string */
	for (str = text_string; *str != 0; ++str)
		put_jtag (*str);

	/* read and echo characters */
	while (1)
	{
		c = get_jtag ( );
		if (c != '\0')
			put_jtag (c);
	}
}
