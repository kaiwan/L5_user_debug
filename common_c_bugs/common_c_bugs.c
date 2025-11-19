/*
 * Inspired by the (old!) article
 * 'The Top 10 Ways to get *crewed by the “C” Programming Language'
 * https://www.real-me.net/ddyer/topten.html
 *
 * Compiler used:
 * gcc 13.3.0
 * gcc -Wall -Wextra -Wconversion -Wsign-conversion -Wshadow -UDEBUG -O2 -Werror=format-security -ansi -std=c99 -std=c11 -std=c18   -D_POSIX_C_SOURCE=201112L -D_DEFAULT_SOURCE -D_GNU_SOURCE -D_FORTIFY_SOURCE=2 common_c_bugs.c -o common_c_bugs
 *
 * clang ver 18.1.3
 * clang -Wall -Wextra -Wconversion -Wsign-conversion -Wshadow -UDEBUG -O2 -Werror=format-security -ansi -std=c99 -std=c11 -std=c18   -D_POSIX_C_SOURCE=201112L -D_DEFAULT_SOURCE -D_GNU_SOURCE -D_FORTIFY_SOURCE=2 common_c_bugs.c -o common_c_bugs
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>		// chmod()
#include <sys/io.h>		// ioperm(), inb()

// 5.
int foo(int a)
{
	if (a)
		return (1);
	/*
	   clang:
	   warning: non-void function does not return a value in all control paths [-Wreturn-type]
	 */
}				/* buggy, because sometimes no value is returned  */

/* 10 : UAR (use-after-return) test case */
static void *uar(void)
{
	char name[32];

	memset(name, 0, 32);
	strncpy(name, "Hands-on Linux Sys Prg", 22);
	/* gcc:
	   warning: ‘__builtin_strncpy’ output truncated before terminating nul copying 22 bytes from a string of the same length [-Wstringop-truncation]
	   FIX:
	   strncpy(name, "Hands-on Linux Sys Prg", 23);
	 */

	return name;
	/* clang:
	   common_c_bugs.c:24:9: warning: address of stack memory associated with local variable 'name' returned [-Wreturn-stack-address]
	   gcc:
	   common_c_bugs.c:24:16: warning: function returns address of local variable [-Wreturn-local-addr]
	 */
}

int main(void)
{
	printf("hello!\n");

#if 1
#if 1
	{
		// 2. Accidental assignment/Accidental Booleans
		int a = 1, b = 2;
		if (a = b)
			printf("a=b shows as True\n");
		else
			printf("a=b shows as False\n");
		/*
		   gcc:
		   common_c_bugs.c:15:13: warning: suggest parentheses around assignment used as truth value [-Wparentheses]
		   15 |         if (a = b)
		   |             ^

		   clang:
		   common_c_bugs.c:17:7: note: use '==' to turn this assignment into an equality comparison
		   17 |         if (a = b)
		   *
		   * Static analysis:
		   * flawfinder: nothing
		   * clang-tidy: clearly catches it
		   *
		   * checkpatch.pl:
		   ERROR: do not use assignment in if condition
		 */
	}
#endif
#if 1
	{
		// 4. Mismatched header files
#define BOOL char
#define BOOL int
		// common_c_bugs.c:43:11: warning: 'BOOL' macro redefined [-Wmacro-redefined]
	}
#endif

	{
		// 5. Phantom returned values
		printf("foo(1) = %d, foo(0) = %d\n", foo(1), foo(0));
		// clang :
		// common_c_bugs.c:13:25: warning: non-void function does not return a value in all control paths [-Wreturn-type]
		// gcc:
		// common_c_bugs.c:13:25: warning: control reaches end of non-void function [-Wreturn-type]
	}

	{
		// 9. C's motto: who cares what it means? I just compile it!
		int a = 2;
		switch (a) {
			int var = 1;	/* This initialization typically does not happen. */
			/* The compiler doesn't complain, but it sure screws things up! */
		case 1:
			printf("case 1; var=%d\n", var);
			break;
			/*
			   gcc:
			   common_c_bugs.c:66:13: warning: statement will never be executed [-Wswitch-unreachable]
			   clang:
			   common_c_bugs.c:68:37: warning: variable 'var' is uninitialized when used here [-Wuninitialized]
			 */
		}
	}

#if 0
	{
		// 10. Unsafe returned values
		char *res = uar();
		printf("res: %s\n", (char *)res);
		// causes a segfault !
	}
#endif

	{
		// 12. Uninitialized local variables
		// The UMR - Uninitialized Memory Reads - bug!
		int b;
		if (b)		/* bug! b is not initialized! */
			printf("UMR: b shows as True (%d)\n", b);
		else
			printf("UMR: b shows as False (0)\n");
		/* gcc:
		   warning: ‘b’ is used uninitialized [-Wuninitialized]
		   clang:
		   warning: variable 'b' is uninitialized when used here [-Wuninitialized]
		 */

		int a;
		char *B;
		if (a)		/* BUG! UMR */
			B = malloc(10);
		/* gcc:
		   warning: ‘a’ is used uninitialized [-Wuninitialized]
		   clang:
		   warning: variable 'a' is uninitialized when used here [-Wuninitialized]
		 */
		if (B) {	/* BUG! B may or may not be initialized */
			*B = a;
			free(B);
		}
		/*
		   clang !
		   warning: variable 'B' is used uninitialized whenever 'if' condition is false [-Wsometimes-uninitialized]
		   warning: implicit conversion loses integer precision: 'int' to 'char' [-Wimplicit-int-conversion]
		 */
	}

	{
		// 13. Cluttered compile time environment
#define BUFFSIZE 2048
		long foo[BUFSIZ];	/* note spelling of BUFSIZ != BUFFSIZE */

		printf("BUFFSIZE=%d BUFSIZ=%d\n", BUFFSIZE, BUFSIZ);
		foo[BUFFSIZE] = 0;

		/*
		   gcc:
		   warning: variable ‘foo’ set but not used [-Wunused-but-set-variable]
		   clang: no warnings

		   Can result in a segfault !
		   ASAN shows 'stack-buffer-overflow ...'
		   LSAN/TSAN/UBSAN all show:
		   'DEADLYSIGNAL
		   ==3682859==ERROR: UndefinedBehaviorSanitizer: SEGV on unknown address ...'
		 */
	}

	{
		// 15. Utterly unsafe arrays
		int thisIsNuts[4];
		int i;
		for (i = 0; i < 10; ++i) {
			thisIsNuts[i] = 0;
			/* Isn't it great ?  I can use elements 1-10 of a 4 element array, and no one cares */
		}
		/*
		   gcc:
		   warning: iteration 4 invokes undefined behavior [-Waggressive-loop-optimizations]
		   clang: no warnings  (??)
		 */
	}
#endif

	{
		// 16. Octal numbers
		int numbers[] = { 001,	// line up numbers for typographical 
			// clarity, lose big time 
			010,	// 8 not 10 
			014
		};		// 12, not 14
		printf("'010' = %d, '014' = %d\n", numbers[1], numbers[2]);
		// o/p: '010' = 8, '014' = 12    (!)

		system("touch dummy");
		// gcc: warning: ignoring return value of ‘system’ declared with attribute ‘warn_unused_result’ [-Wunused-result]
		chmod("dummy", 644);
		system("ls -l dummy");
		// o/p: --w----r-T 1 kaiwan kaiwan 0 Sep 26 08:32 dummy   (see the mode!)
		// FIX:
		chmod("dummy", 0644);
		system("ls -l dummy");
		system("rm dummy");
	}

	{
		// 17. Signed Characters/Unsigned bytes
		char naive_val;
		unsigned char correct_val;

		// int ioperm(unsigned long from, unsigned long num, int turn_on);
		// If turn_on is nonzero, the calling thread must be privileged (CAP_SYS_RAWIO)
		// NEED to run this as root or with CAP_SYS_RAWIO !!!
#define MYPORT 0x20
		if (ioperm(MYPORT, 32, 1) < 0) {
			perror("ioerm() failed");
			exit(1);
		}
		// unsigned char inb(unsigned short port);
		naive_val = inb(0x20);
		correct_val = inb(0x20);
		printf("naive_val = 0x%x, correct_val = 0x%x\n", naive_val,
		       correct_val);

		/*
		   gcc:
		   warning: conversion to ‘char’ from ‘unsigned char’ may change the sign of the result [-Wsign-conversion]
		   clang:
		   warning: implicit conversion changes signedness: 'unsigned char' to 'char' [-Wsign-conversion]
		   naive_val = inb(0x20);
		   ~ ^~~~~~~~~
		 */
	}

	exit(0);
}
