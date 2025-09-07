# Makefile
ALL := fork_test pthread_test fork_test_dbg pthread_test_dbg
CC := ${CROSS_COMPILE}gcc

all: ${ALL}
fork_test: fork_test.c
	${CC} fork_test.c -o fork_test -Wall -O2
fork_test_dbg: fork_test.c
	${CC} fork_test.c -o fork_test_dbg -Wall -O0 -g
pthread_test: pthread_test.c
	${CC} pthread_test.c -o pthread_test -Wall -pthread -O2
pthread_test_dbg: pthread_test.c
	${CC} pthread_test.c -o pthread_test_dbg -Wall -pthread -O0 -g
clean:
	rm -fv ${ALL}
