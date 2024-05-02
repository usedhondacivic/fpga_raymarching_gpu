/* This program demonstrates use of floating-point numbers in the computer
 *
 * It performs the following: 
 * 	1. reads two FP numbers from the Terminal window
 * 	2. performs +, -, *, and / on the numbers, then prints results on Terminal window
 */
#include <stdio.h> 
 
int flush()
{
    while (getchar()!='\n');
    return 1;
} 

int main(void)
{
	float x, y, add, sub, mult, div;

	while(1)
	{
		printf ("Enter FP values X: ");

        while((scanf ("%f", &x) != 1) && flush());      // get valid floating point value and flush the invalid input
		printf ("%f\n", x);     // echo the typed data to the Terminal window

		printf ("Enter FP values Y: ");        
        
		while((scanf ("%f", &y) != 1) && flush());      // get valid floating point value and flush the invalid input
		printf ("%f\n", y);     // echo the typed data to the Terminal window        
        
		add = x + y;
        sub = x - y;
		mult = x * y;
		div = x / y;
		printf ("X + Y = %f\n", add);
		printf ("X - Y = %f\n", sub);
		printf ("X * Y = %f\n", mult);
		printf ("X / Y = %f\n", div);
	}
}
