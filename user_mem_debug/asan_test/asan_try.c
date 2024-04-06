#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#define QP	fprintf(stderr, "%s:%s:%d\n", __FILE__, __func__, __LINE__);

static int gArr[10]; // sizeof(int) = 4, hence 4*10 = 40 bytes here, from 0-9
int main(int argc, char **argv)
{
	QP;
	/* asan-globals : Enable buffer overflow detection for global objects. */
	gArr[argc+10]=7; 
		/* gArr[1+10] I.e. gArr[11]=7; But only gArr[] 0-9 is valid memory!
		* Thus, we have a right (write) overflow by 4*2=8 bytes!
		* ASAN Shadow memory (SM): each byte of shadow memory == 8 bytes of 		* ‘real’ memory. If all ok, it’s value shows as 00. If not 00, it’s 		* number of bytes that are okay.
		* So here, ASAN shadow memory shows as:
		* =>0x0ac07b873a30: 00[f9]f9 f9 f9 f9 f9 f9 00 00 00 00 00 00 00 00
		* [ … ] 
		* Global redzone:          f9
		* [f9] is showing that it’s the global memory redzone that’s
		* overwritten; it’s 1 byte of SM, thus 8 bytes of real memory.
		*/
	exit (EXIT_SUCCESS);
}
