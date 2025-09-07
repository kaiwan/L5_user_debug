# Makefile
ALL := thrd_matrixmul thrd_matrixmul_dbg
CC := ${CROSS_COMPILE}gcc

all: ${ALL}
thrd_matrixmul: thrd_matrixmul.c
	${CC} thrd_matrixmul.c -o thrd_matrixmul -Wall -O2 -pthread
thrd_matrixmul_dbg: thrd_matrixmul.c
	${CC} thrd_matrixmul.c -o thrd_matrixmul_dbg -Wall -O0 -g -pthread
clean:
	rm -fv ${ALL}
