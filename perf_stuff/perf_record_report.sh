#!/bin/bash
# Small tests:
# Using perf to record and report - profile - CPU usage.
# (c) Kaiwan NB, kaiwanTECH
# License: MIT.
name=$(basename $0)

die()
{
echo >&2 "FATAL: $@"
exit 1
}
# runcmd
# Parameters
#   $1 ... : params are the command to run
runcmd()
{
	[[ $# -eq 0 ]] && return
	echo "$@"
	eval "$@"
}

SAMPLING_FREQ=99
TIME=10s

process_report()
{
  local SPEEDSCOPE_FILE="callstacks4speedscope_${FUNCNAME[1]}.txt"
  echo "
[+] Reporting ..."
  runcmd "perf report --sort cpu,comm --stdio-color"
  # Can examine the callstacks (flamegraph/flamechart?) in speedscope
  # https://www.speedscope.app/
  runcmd "perf script -i perf.data > ${SPEEDSCOPE_FILE}"
  chown ${LOGNAME}:${LOGNAME} ${SPEEDSCOPE_FILE}
  ls -l $(realpath ${SPEEDSCOPE_FILE})
  echo "> Open this file in the speedscope web app https://www.speedscope.app/"
}
trap process_report INT QUIT

test1_malloc()
{
  echo "[+] test1_malloc(): recording ... pl wait for time of ${TIME} ..."
  runcmd "perf record -F ${SAMPLING_FREQ} \
	--call-graph dwarf \
	-- taskset 01 stress-ng --malloc 1 \
	-t ${TIME}"
  process_report
}

test2_matrixmul_pthrd()
{
 local PRG=./thrd_matrixmul_dbg
 cd matrixmul/thrd_matrixmul
 [[ ! -f ${PRG} ]] && {
    make thrd_matrixmul_dbg || die "failed"
 }

  echo "[+] test2_matrixmul_pthrd(): recording ... pl wait ..."
  runcmd "perf record -F ${SAMPLING_FREQ} \
	-a \
	--call-graph dwarf \
	-- ${PRG}"
  # -a : sample across all cpu cores
  process_report
}

#--
# Src for this demo's here:
#  https://github.com/kaiwan/cpu_sched_demo
# Params
#  $1 : 0 = run the prg ver compiled without symbols
#       1 = run the prg ver compiled with symbols
test3_cpusched_mt_demo()
{
  local PRG=./sched_pthrd_rtprio_dbg
  local ARGS="32"

  echo -n "*** Running program "
  [[ $1 -eq 0 ]] && {
    PRG=./sched_pthrd_rtprio
    echo "WITHOUT symbols ***"
  } || {
    echo "WITH symbols ***"
  }
 cd sched_pthrd_rtprio
 [[ ! -f ${PRG} ]] && {
    make || die "failed"
 }
  [[ ! -f ${PRG} ]] && die "Program \"${PRG}\" not found."

  echo "[+] test3_cpusched_mt_demo(): recording ... pl wait ..."
  runcmd "perf record -F ${SAMPLING_FREQ} \
	-C 0 \
	--call-graph dwarf \
	-- taskset 01 ${PRG} ${ARGS}"
  # -C 0 : only on cpu #0
  process_report
}

test4_fork_exit()
{
 local PRG=./fork_test_dbg
 cd fork_pthrd_test/
 [[ ! -f ${PRG} ]] && {
    make fork_test_dbg || die "failed"
 }

  echo "[+] test4_fork_exit(): recording ... pl wait ..."
  runcmd "perf record -F ${SAMPLING_FREQ} \
	-C 1 \
	--call-graph dwarf \
	-- taskset 02 ${PRG}"
  # -C 1 : only on cpu #1
  process_report
}

test5_pthread_exit()
{
 local PRG=./pthread_test_dbg
 cd fork_pthrd_test
 [[ ! -f ${PRG} ]] && {
    make pthread_test_dbg || die "failed"
 }

  echo "[+] test5_pthread_exit(): recording ... pl wait ..."
  runcmd "perf record -F ${SAMPLING_FREQ} \
	-C 1 \
	--call-graph dwarf \
	-- taskset 02 ${PRG}"
  # -C 1 : only on cpu #1
  process_report
}

menu()
{
echo "--------------- MENU --------------------

Select a test case to run under perf:

1. malloc() stress test (via stress-ng)
2. matrixmul pthread app
3. CPU sched pthread demo app : without symbols
4. CPU sched pthread demo app : with symbols
5. fork-exit in loop app
6. pthread-exit in loop app
7. Clean (remove all perf.data* and speedscope* files)
8. Quit
"
read choice
case ${choice} in
  1) test1_malloc
     ;;
  2) test2_matrixmul_pthrd
     ;;
  3) test3_cpusched_mt_demo 0  # without symbols
     ;;
  4) test3_cpusched_mt_demo 1  # with symbols (in the app only)
     ;;
  5) test4_fork_exit
     ;;
  6) test5_pthread_exit
     ;;
  7) find . -type f \( -name "perf.data*" -o -name "callstacks4speedscope*" \) -delete
     ;;
  8) echo "Exiting..." ; exit 0
     ;;
  *) echo "Invalid choice" ; exit 1
esac
}


#--- 'main' ---
[[ $(id -u) -ne 0 ]] && die "${name}: need root."
which stress-ng >/dev/null || die "pl install the stress-ng package"
menu
exit 0
