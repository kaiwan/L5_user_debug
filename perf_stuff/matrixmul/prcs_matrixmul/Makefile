# Makefile
ALL := prcs_matrixmul prcs_matrixmul_dbg
CC := ${CROSS_COMPILE}gcc

all: ${ALL}
prcs_matrixmul: prcs_matrixmul.c
	${CC} prcs_matrixmul.c -o prcs_matrixmul -Wall -O2 -pthread
prcs_matrixmul_dbg: prcs_matrixmul.c
	${CC} prcs_matrixmul.c -o prcs_matrixmul_dbg -Wall -O0 -g -pthread
clean:
	rm -fv ${ALL}
