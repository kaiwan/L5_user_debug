# Makefile
ALL := sched_pthrd_rtprio sched_pthrd_rtprio_dbg
CC := ${CROSS_COMPILE}gcc

all: ${ALL}
sched_pthrd_rtprio: sched_pthrd_rtprio.c
	${CC} sched_pthrd_rtprio.c -o sched_pthrd_rtprio -Wall -O2 -pthread
sched_pthrd_rtprio_dbg: sched_pthrd_rtprio.c
	${CC} sched_pthrd_rtprio.c -o sched_pthrd_rtprio_dbg -Wall -O0 -g -pthread
clean:
	rm -fv ${ALL}
