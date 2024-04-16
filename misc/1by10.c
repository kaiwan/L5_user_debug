/*
 * 1by10.c
 * Dividing 1.0 by 10.0 (floating point) shows the result:
 *  0.100000000000000005551115123126
 * clearly demonstrating how the number of digits of precision matters!
 * (Here, the 55111... portion begins after 18 digits! If the register holding
 * the result is smaller, it gets truncated. With something like a missile
 * tracking system, this truncation can be quite literally fatal! ...As was the
 * case with the Patriot Scud-missile-killer in the Gulf War in 1991, when it missed).
 */
#include <stdio.h>

long double res = 0; /* (long) double precision
 * "at least 15 decimals will always be correct ..."
 * ref: https://stackoverflow.com/questions/28045787/how-many-decimal-places-does-the-primitive-float-and-double-support
 */

int main()
{
#include <float.h>
	printf(
"float digits:       FLT_DIG=%d\n\
double digits:      DBL_DIG=%d\n\
long double digits: LDBL_DIG=%d\n\n",
		FLT_DIG, DBL_DIG, LDBL_DIG);
	/*
	 * On my x86_64, Ubuntu 23.10, I get:
	 * float digits:       FLT_DIG=6
	 * double digits:      DBL_DIG=15
	 * long double digits: LDBL_DIG=18
	 *
	 * Looks like 18 places of decimal accuracy is the max.
	 */

	res = 1.0/10.0;
	printf("res of 1.0/10.0 is:\n"
" 3 places accuracy: %.3Lf\n"
"15 places accuracy: %.15Lf\n"
"18 places accuracy: %.18Lf\n"
"20 places accuracy: %.20Lf\n"
	, res, res, res, res);
}
