#include <stdio.h>
#include <unistd.h>
#include <signal.h>

static void gotit(int sig)
{
	printf("%s(): got it!\n", __func__);
}

int main(void)
{
	int i;

	signal(SIGINT, gotit);
	printf("PID: %d\nsleep ...\n", getpid());
	pause();
//	sleep(5);

	//for (i = 1; i < 10000; i++) {
	for (i = 1; i < 10; i++) {
		if (i % 3 == 0)
			printf("%d is divisible by 3\n", i);
		if (i % 11 == 0)
			printf("%d is divisible by 11\n", i);
	}

	return 0;
}
