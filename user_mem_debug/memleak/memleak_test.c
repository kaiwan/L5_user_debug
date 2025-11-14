// memleak_test.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Trivial test case below test1() does NOT show the desired result
 * - the malloc() and free() APIs don't show up in the FlameGraph!
 * Why?? The usual reason is lack of symbols (but we have 'em), no frame
 * pointers - but we run the FG w/ the --call-graph option which takes
 * care of that !
 * So: we require a large sample size and more importantly, some *actual work*
 * done in the malloc() so as to not have the comiler optimize it away!
 * This is done in test2()... and it works.
 */

#if 0
#define NUM	5
static int pgsz;

static int test1(void)
{
	int i;
	char *p[NUM];

	for (i = 0; i < NUM; i++) {
		p[i] = malloc(2 * pgsz);
		if (!p[i])
			return -1;
#if 0
		memset((p[i] + 16), 0, sizeof(size_t));	// set a byte in the first page
		memset((p[i] + pgsz + 16), 0, sizeof(size_t));	// set a byte in the second page
		// the above memset()'s ensure phy RAM's allocated now
#endif
		printf("p[%d] alloc'ed now\n", i);

		/* Ah, interesting! to have perf 'see' the code paths around malloc() and
		 * subsequent free(), we need to delay the execution and raise the frequency
		 * (am using -f 4000 (4000 HZ!) in the flame_grapher script)
		 */
		sleep(0.3);
	}

	puts("");
	for (i = 0; i < NUM; i++) {
		// Whoops, only some free()'s ; Leakage!
		if ((i % 2) == 0) {
			free(p[i]);
			printf("p[%d] free'd now\n", i);
			sleep(0.3);
		}
	}

	return 0;

}
#endif

#define NUM_LARGE	10000000
static void *p[NUM_LARGE];
int test2(void)
{
	volatile int i;

	for (i = 0; i < NUM_LARGE; i++) {
		// Vary alloc size to help defeat caching/optimization
		size_t size = 1024 + (i % 1024);
		p[i] = malloc(size);
		if (!p[i]) {
			printf("malloc failed after %d iters\n", i);
			exit(1);
		}
	}
	for (i = 0; i < NUM_LARGE; i++) {
		// Whoops, only some free()'s ; Leakage!
		if ((i % 2) == 0)
			free(p[i]);
	}
	return 0;
}

int main(int argc, char **argv)
{
//      pgsz = getpagesize();
//      test1();
	test2();
	return 0;
}
