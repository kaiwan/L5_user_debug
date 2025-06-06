# Makefile
# for Linux Debugging trg for 1_buggy.c
# 
# To build normally, for x86[_64]:
# make x86_all
#
# For ARM cross compilation, set the env var
# CROSS_COMPILE to the cross compiler prefix when invoking make, for eg. :
# make CROSS_COMPILE=arm-none-linux-gnueabi- arm_all
#
# Kaiwan NB, kaiwanTECH.

CC := ${CROSS_COMPILE}gcc
DBG_FLAGS := -g -ggdb -gdwarf-4 -Og -DDEBUG
# Why -Og and not -O0?
# man gcc
# '... Optimize debugging experience.  -Og should be the optimization level of
# choice for the standard edit-compile-debug cycle, offering a reasonable level
# of  optimization  while maintaining  fast  compilation  and a good debugging
# experience. It is a better choice than -O0 for producing debuggable code
# because some compiler passes that collect debug information are disabled at -O0.'
x86_ALL := 1_buggy_rel 1_buggy_dbg 1_buggy_asan 1_buggy_lsan 1_buggy_tsan   #buggy-CORRECTED 1_buggy_sym_32 1_buggy_nosym_32 
x86_all: ${x86_ALL}
ARM_ALL := arm_1_buggy_nosym arm_1_buggy_sym arm_buggy_CORRECTED
arm_all: ${ARM_ALL}
all : ${x86_ALL}

1_buggy_dbg: 1_buggy.c
	${CC} ${DBG_FLAGS} 1_buggy.c -o 1_buggy_dbg -Wall
1_buggy_rel: 1_buggy.c
	${CC} -O2 1_buggy.c -o 1_buggy_rel -Wall
	strip --strip-all 1_buggy_rel
buggy-CORRECTED: buggy_CORRECTED.c
	${CC} ${DBG_FLAGS} buggy_CORRECTED.c -o buggy_CORRECTED -Wall

1_buggy_sym_32: 1_buggy.c
	${CC} ${DBG_FLAGS} -m32 1_buggy.c -o 1_buggy_sym_32 -Wall
1_buggy_nosym_32: 1_buggy.c
	${CC}  -m32 -O2 1_buggy.c -o 1_buggy_nosym_32 -Wall
	strip --strip-all 1_buggy_nosym_32

arm_1_buggy_sym: 1_buggy.c
	${CC} ${DBG_FLAGS} 1_buggy.c -o arm_1_buggy_sym -Wall
arm_1_buggy_nosym: 1_buggy.c
	${CC} -O2 1_buggy.c -o arm_1_buggy_nosym -Wall
	${CROSS_COMPILE}strip --strip-all arm_1_buggy_nosym
arm_buggy_CORRECTED: buggy_CORRECTED.c
	${CC} ${DBG_FLAGS} buggy_CORRECTED.c -o arm_buggy_CORRECTED -Wall

disas_arm_sym:
	$(info Invoking helper script ./disas_arm.sh now..)
	./disas_arm.sh arm_1_buggy_dbg

clean:
	rm -f *.o ${x86_ALL} ${ARM_ALL}
