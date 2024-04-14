#include <stdio.h>
#include <unistd.h>

static void do_work(void)
{
	int i;

	for (i = 1; i < 10; i++) {
		if (i % 3 == 0)
			printf("%d is divisible by 3\n", i);
		if (i % 11 == 0)
			printf("%d is divisible by 11\n", i);
	}
}

int main(void)
{
	int dly = 60;

#ifdef DEBUG
	printf("Debug artifact: PID %d sleeping for %ds now...\n",
	       getpid(), dly);
	sleep(dly);
#endif
	do_work();
	return 0;
}
