int main(void)
{
	int i;

	printf("PID: %d\nsleep 5 ...\n", getpid());
	sleep(5);

	for (i = 1; i < 10000; i++) {
		if (i % 3 == 0)
			printf("%d is divisible by 3\n", i);
		if (i % 11 == 0)
			printf("%d is divisible by 11\n", i);
	}

	return 0;
}
