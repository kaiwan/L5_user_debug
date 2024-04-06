#!/bin/bash
# genfg.sh
# Given the perf data file, generates a CPU FlameGraph !
#
# CPU FlameGraph wrapper script.
# Simple wrapper over Brendan Gregg's superb FlameGraphs!
# CREDITS: Brendan Gregg, for the original & simply superb FlameGraph
#
# Kaiwan N Billimoria
# (c) 2016,2022 kaiwanTECH
# License: MIT

# 3 params passed:
# $1 : perf data file (usually perf.data)
# $2 : result folder
# $3 : SVG filename
# $4 : style to draw graph in
#        0 => regular
#        1 => icicle (downward-growing!)
name=$(basename $0)
#echo "#p = $# p= $*"

[ $# -lt 4 ] && {
# echo "${name}: should be invoked by the flame_grapher.sh script, not directly!"
 echo "Usage: ${name} perf-data-file result-folder SVG-filename style-to-display type
  style: 0 = normal, 1 = icicle
  type : 0 = normal, 1 = flame-chart"
 exit 1
}

export FLMGR=~/FlameGraph  # location of code
INFILE=$1
OUTFILE=$3
STYLE=$4
TYPE=$5

TOPDIR=${PWD}
cd ${2} || exit 1
#pwd

[ ! -f ${INFILE} ] && {
  echo "${name} : perf data file ${INFILE} invalid? Aborting..."
  cd ${TOPDIR}
  exit 1
}
if [ ${STYLE} -ne 0 -a ${STYLE} -ne 1 ] ; then
		echo "${name}: parameter graph-style must be 0 (normal) or 1 (icicle)"
	exit 1
fi
if [ ${TYPE} -ne 0 -a ${TYPE} -ne 1 ] ; then
		echo "${name}: parameter graph-type must be 0 (normal) or 1 (flame-chart)"
	exit 1
fi

echo
echo "${name}: Working ... generating SVG file \"${2}/${OUTFILE}\"..."

#---
# Interesting options to flamegraph.pl:
# (ref: https://github.com/brendangregg/FlameGraph )
# --title TEXT     # change title text
# --subtitle TEXT  # second level title (optional)
# --inverted       # icicle graph ; downward-growing
# --flamechart     # produce a flame chart (sort by time, do not merge stacks)
# --width NUM      # width of image (default 1200)
# --hash           # colors are keyed by function name hash
# --cp             # use consistent palette (palette.map)
# --notes TEXT     # add notes comment in SVG (for debugging)
WIDTH=1900  # can make it v large; you'll just have to scroll horizontally...
TITLE="CPU mixed-mode Flame"
# ${name} perf-data-file result-folder SVG-filename style-to-display(1 for icicle) type(1 for FlameChart)"
#            p1               p2           p3               p4:STYLE                      p5:TYPE
[ ${TYPE} -eq 1 ] && PTYPE=--flamechart
NOTES="notes text: "
if [ ${STYLE} -eq 0 ] ; then
   [ ${TYPE} -eq 0 ] && {
     TITLE="${TITLE}Graph ${OUTFILE} ; style is normal (upward-growing stacks), type is graph"
	 NOTES="${NOTES}FlameGraph, type normal"
   } || {
     TITLE="${TITLE}Graph ${OUTFILE} ; style is normal (upward-growing stacks), type is chart"
	 NOTES="${NOTES}FlameGraph, type chart"
   }
   sudo chown $(whoami) ${INFILE}
   #sudo perf script --input ${INFILE} -f | ${FLMGR}/stackcollapse-perf.pl | \
   sudo perf script --input ${INFILE} -f \
#		  -F comm,pid,tid,cpu,time,event,ip,sym,dso,trace \
		   | ${FLMGR}/stackcollapse-perf.pl | \
	  ${FLMGR}/flamegraph.pl  --title "${TITLE}" --subtitle "${OUTFILE}" ${PTYPE} \
	  --notes "${NOTES}" --width ${WIDTH} > ${OUTFILE} || {
     echo "${name}: failed."
     exit 1
   }
else
  [ ${TYPE} -eq 1 ] && {
	 TITLE="${TITLE}Chart ${OUTFILE}; style is flamechart (all stacks, X-axis is timeline)"
	 NOTES="${NOTES}FlameChart, type flamechart"
  } || {
	 TITLE="${TITLE}Graph ${OUTFILE}; style is flamegraph (merged stacks)"
	 NOTES="${NOTES}FlameGraph, type normal"
  }
  sudo perf script --input ${INFILE} -f | ${FLMGR}/stackcollapse-perf.pl | \
	  ${FLMGR}/flamegraph.pl --title "${TITLE}" --subtitle "${OUTFILE}" --inverted ${PTYPE} \
	  --notes "${NOTES}" --width ${WIDTH} > ${OUTFILE} || {
     echo "${name}: failed."
     exit 1
  }
fi

USERNM=$(echo ${LOGNAME})
sudo chown -R ${USERNM}:${USERNM} ${TOPDIR}/${1}/ 2>/dev/null
cd ${TOPDIR}
ls -lh ${1}/${OUTFILE}
echo
echo "View the above SVG file in your web browser to see and zoom into the CPU FlameGraph."

echo "<NOTES:> in the SVG (if any):"
grep -w "NOTES\:" ${1}/${OUTFILE}
#exit 0
