#!/bin/bash
name=$(basename $0)

die()
{
echo >&2 "FATAL:${name}: $*" ; exit 1
}
warn()
{
echo >&2 "WARNING:${name}: $*"
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


#--- 'main' here

which xxd >/dev/null || die "Install xxd and retry"
which gdb >/dev/null || die "Install gdb and retry"

[[ $# -ne 1 ]] && die "Usage: ${name} show_secret
 show_secret set to 1 => we don't call madvise(...MADV_DONTDUMP) and thus allow the 'secret' to show in the core dump
 show_secret set to 0 => we DO call madvise(...MADV_DONTDUMP) and thus do NOT allow the 'secret' to show in the core dump"

make clean >/dev/null 2>&1 || exit 1
make >/dev/null 2>&1 || die "make failed"
runcmd "rm -f core*"

#PRG=1_buggy_madvise_dbg
PRG=1_buggy_madvise
ulimit -c unlimited
echo "----------------------------------------------------------------------"
[[ $1 -eq 1 ]] && echo "show_secret set to 1 => we don't call madvise(...MADV_DONTDUMP) and thus allow the 'secret' to show in the core dump"
[[ $1 -eq 0 ]] && echo "show_secret set to 0 => we DO call madvise(...MADV_DONTDUMP) and thus do NOT allow the 'secret' to show in the core dump"

runcmd "./${PRG} $1"   ### CRASH! Segfault and coredump
echo "----------------------------------------------------------------------"
mv core* core_run

# This works when madvise() isn't called and the debug version's crashed; the
# core dump contains the secret!
# BUT even when we crash and coredump via the *release* ver, the GDB '2-part solution'
# feature to retrive symbols and thus examine the core works, thus we still
# see the secret!
runcmd "xxd core_run |grep -C1 \"XECRET\""

echo
echo "----------------------------------------------------------------------"
echo "gdb -c ./core_run ${PRG}"
echo "----------------------------------------------------------------------"
# run gdb in batch mode
gdb </dev/null \
	--nx --batch --readnever -iex 'set debuginfod enabled off' \
	-ex "set pagination off" -ex "set height 0" -ex "set width 0" \
	"${dump_all_cmds[@]}" \
	-q -c ./core_run ./1_buggy_madvise \
	-ex 'x/s (void *)sbuf' \
	-ex quit

# F.e.
# (gdb) x/s sbuf
# 0x55a69b4c2000:	"XECRETXECRET"

# When run with param 0, i.e. with the madvise() MADV_DONTDUMP, this is the result:
# (gdb) x/s sbuf
# 0x55a4d5c09000:	""
# It's not present. Fantastic.
