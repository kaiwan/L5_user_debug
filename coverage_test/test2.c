#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

// QuickPrint !
#define QP printf(" In %s:%s():%d\n", __FILE__, __func__, __LINE__);

void foo(void)
{
	QP;
}

void bar(void)
{
	QP;
}

void oof(void)
{
	QP;
}

int main(int argc, char **argv)
{
	if (argc != 2) {
		fprintf(stderr, "Usage: %s case# [1-3]\n", argv[0]);
		exit(1);
	}

	switch (atoi(argv[1])) {
	case 1:
		printf("case 1\n");
		foo();
		break;
	case 2:
		printf("case 2\n");
		bar();
		break;
	case 3:
		printf("case 3\n");
		oof();
		break;
	default:
		printf("invalid case\n");
		exit(1);
	}
	exit(0);
}
