#!/bin/bash
# Generate CPU FlameGraph wrapper script.
# Simple wrapper over Brendan Gregg's superb CPU FlameGraphs!
# Part 1 of 2.
# This script records the perf data file, and then invokes the
# second script 2flameg.sh which renders the SVG file.
# All "result" files are under the 'result/' folder.
#
# CREDITS: Brendan Gregg, for the original & simply superb FlameGraph
#
# Kaiwan N Billimoria, kaiwanTECH
# License: MIT

# Turn on unofficial Bash 'strict mode'! V useful
# "Convert many kinds of hidden, intermittent, or subtle bugs into immediate, glaringly obvious errors"
# ref: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
name=$(basename "$0")
PDIR=$(which "$0")
[ -z "${PDIR}" ] && PDIR=$(dirname "$0")  # true if this script isn't in PATH
export PFX=$(dirname "${PDIR}")		# dir in which this script and tools reside
export FLMGR=~/FlameGraph		# location of original BGregg's FlameGraph repo code
PERF_RESULT_DIR_BASE=/tmp/flamegraphs	# change to make it non-volatile
STYLE_INVERTED_ICICLE=0
TYPE_CHART=0
HZ=99

# TODO
#  [*] add -c cmdline option
#  [ ] add -d duration param
#  [ ] show current config on run
# ISSUES
#  [ ] why does 2flameg.sh seem to run twice?? the 'exit' and ^C ?

usage()
{
  echo "Usage: ${name} -o svg-out-filename(without .svg) [options ...]
  -o svg-out-filename(without .svg) : MANDATORY: name of SVG file to generate (saved under ${PERF_RESULT_DIR_BASE}/)
Optional switches:
 [-c \"command\"]: \"command\" = Generate a FlameGraph for ONLY this command-line (it's process's/threads)
                             You MUST specify the command to run within quotes.
                             If neither -c nor -p is passed, the *entire system* is sampled...
 [-p PID]     : PID        = Generate a FlameGraph for ONLY this process or thread
                             If neither -c nor -p is passed, the *entire system* is sampled...
 Note: -c \"cmd\" and -p PID are mutually exclusive options; you can specify only one of them.
 [-s <style>] : normal     = Draw the stack frames growing upward   [default]
                icicle     = Draw the stack frames growing downward
 [-t <type>]  : graph      = Produce a flame graph (X axis is NOT time, merges stacks) [default]
                             Good for performance outliers (who's eating CPU? using max stack?);
			     works well for multi-threaded apps
                chart      = Produce a flame chart (sort by time, do not merge stacks)
                             Good for seeing all calls; works well for single-threaded apps
 [-f <freq>]  : freq (HZ)  = Have perf sample the system/process at [default=${HZ}]
                             Too high a value here can cause issues
 -h|-?        : show this help screen.

NOTE:
- After pressing ^C to stop, please be patient... it can take a while to process.
- The FlameGraph SVG (and perf.data file) are stored in the volatile ${PERF_RESULT_DIR_BASE} dir;
  copy them to a non-volatile location to save them."
}

function die
{
echo >&2 "${name}: *FATAL*  $@"
exit 1
}


### "main" here

which perf >/dev/null 2>&1 || die "${name}: perf not installed? Aborting...
 Tip- (Deb/Ubuntu) sudo apt install linux-tools-$(uname -r) linux-tools-generic"
[ ! -f ${PFX}/2flameg.sh ] && die "The part-2 script 2flameg.sh is missing? Aborting..."
#[ ! -f ./2flameg.sh ] && die "The part-2 script 2flameg.sh is missing? Aborting..."
[ ! -d ${FLMGR} ] && die "I find that the original FlameGraph GitHub repo isn't installed.
 You need to (one-time) install it (under your home dir).
 In your terminal window/shell, type (including the parentheses) -OR- simply copy-paste the line below:
 (cd; git clone https://github.com/brendangregg/FlameGraph)"
[ $# -lt 1 ] && {
  usage
  exit 1
}
[ "$1" = "--help" ] && {
  usage
  exit 0
}

#--- getopts processing
optspec=":o:c:p:s:t:f:h?" # a : after an arg implies it expects an argument
unset PID
# To prevent shellcheck's 'unbound variable' error:
OUTFILE="" ; CMD="" ; PID="" #; STYLE=""; TYPE=""; HZ=""
while getopts "${optspec}" opt
do
    #echo "opt=${opt} optarg=${OPTARG}"
    case "${opt}" in
	  o)
 	        OUTFILE=${OPTARG}
	        #echo "-o passed; outfile=${OUTFILE}"
		;;
	  c)
		CMD="${OPTARG}"
	        #echo "-c passed; cmd=${CMD}"
		;;
	  p)
 	        PID=${OPTARG}
	        #echo "-p passed; PID=${PID}"
		# Check if PID is valid
		sudo kill -0 "${PID}" 2>/dev/null
		[ $? -ne 0 ] && die "PID ${PID} is an invalid (or dead) process/thread?"
		;;
	  s)
	        STYLE=${OPTARG}
	        #echo "-s passed; STYLE=${STYLE}"
		if [ "${STYLE}" != "normal" ] && [ "${STYLE}" != "icicle" ]; then
			usage ; exit 1
		fi
		[ "${STYLE}" = "icicle" ] && STYLE_INVERTED_ICICLE=1
		;;
	  t)
 	        TYPE=${OPTARG}
	        #echo "-f passed; TYPE=${TYPE}"
		if [ "${TYPE}" != "graph" ] && [ "${TYPE}" != "chart" ]; then
			usage ; exit 1
		fi
		[ "${TYPE}" = "chart" ] && TYPE_CHART=1
		;;
	  f)
 	        HZ=${OPTARG}
	        echo "-f passed; HZ=${HZ}"
		;;
	  h|?)
		 usage
		 exit 0
		;;
	  *)	echo "Unknown option '-${OPTARG}'" ; usage; exit 1
		;;
  	  esac
done
shift $((OPTIND-1))

[ -z "${OUTFILE}" ] && {
  usage ; exit 1
}
[[ "${OUTFILE}" = *"."* ]] && die "Please ONLY specify the name of the SVG file; do NOT put any extension"
[[ -n ${PID} ]] && [[ -n ${CMD} ]] && die "Specify EITHER the command-to-run (-c) OR the process PID (-p), not both"
SVG=${OUTFILE}.svg
PDIR=${PERF_RESULT_DIR_BASE}/${OUTFILE}
TOPDIR=$(pwd)
#red_fg "pwd = $(pwd); TOPDIR=${TOPDIR}; PFX=${PFX}"

#--- Run the part 2 - generating the FG - on interrupt or exit !
trap 'ls -lh perf.data; cd ${TOPDIR}; sync ; ./2flameg.sh ${PDIR} ${SVG} ${STYLE_INVERTED_ICICLE} ${TYPE_CHART} "${CMD}"' INT EXIT
#trap 'cd ${TOPDIR}; echo Aborting run... ; sync ; exit 1' QUIT
#---

mkdir -p "${PDIR}" || die "mkdir -p ${PDIR}"
sudo chown -R "${LOGNAME}":"${LOGNAME}" ${PERF_RESULT_DIR_BASE} 2>/dev/null
cd "${PDIR}" || echo "*Warning* cd to ${PDIR} failed"

MSG_CMDLINE_STOP="Please DO allow the command to complete ...
If you Must stop it, press ^C ...
 *NOTE* After pressing ^C to stop it, PLEASE be patient... it can take a while to process..."
MSG_STOP="Press ^C to stop...
 *NOTE* After pressing ^C to stop, PLEASE be patient... it can take a while to process..."

if [ ! -z "${CMD}" ]; then  #------------------ Profile a particular command-line
 echo "### ${name}: recording samples on the command \"${CMD}\" now...
 ${MSG_CMDLINE_STOP}"
 sudo perf record -F "${HZ}" --call-graph dwarf ${CMD} || exit 1	# generates perf.data
elif [ ! -z "${PID}" ]; then  #------------------ Profile a particular process
 echo "### ${name}: recording samples on process PID ${PID} now...
 ${MSG_STOP}"
 sudo perf record -F "${HZ}" --call-graph dwarf -p "${PID}" || exit 1	# generates perf.data
else                        #---------------- Profile system-wide
 echo "### ${name}: recording samples system-wide now...
 ${MSG_STOP}"
 sudo perf record -F "${HZ}" --call-graph dwarf -a || exit 1		# generates perf.data
fi
cd ${TOPDIR} || echo "*Warning* cd to ${TOPDIR} failed"

#exit 0  # this exit causes the 'trap' to run (as we've trapped the EXIT!)
