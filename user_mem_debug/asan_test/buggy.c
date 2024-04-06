
#include <stdio.h>
#include <unistd.h>
#include <string.h>

static void buggy1(void)
{
	char arr[5], tmp[8];

	printf("arr=%p tmp=%p\n", arr, tmp);
	memset(arr, 'a', 5);
	memset(tmp, 't', 8);
	tmp[7] = '\0';
	printf("arr = %s\n", arr);
}

int main()
{
	buggy1();
}
