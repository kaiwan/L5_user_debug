/*
 * 1_buggy_madvise.c
 * 
 *
 * The purpose of this simple program is:
 *  Given a pathname as a parameter, it queries and prints some
 *  information about it (retrieved from it's inode using the 
 *  stat(2) syscall).
 * 
 * (c) Kaiwan NB, kaiwanTECH
 */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/mman.h>

#define NUM	128

//static char *sbuf; // interesting; decl it as 'static' and it doesn't show up! ??
void *sbuf;

main(int argc, char **argv)
{
	struct stat statbuf;
	int pgsz = getpagesize();

	if (argc != 2) {
		fprintf(stderr, "Usage: %s show_secret\n"
			" show_secret set to 1 => we don't call madvise(...MADV_DONTDUMP) and thus allow the 'secret' to show in the core dump\n"
			" show_secret set to 0 => we DO call madvise(...MADV_DONTDUMP) and thus do NOT allow the 'secret' to show in the core dump\n",
			argv[0]);
		exit(1);
	}
	int show_secret = atoi(argv[1]);

	/* Retrieve the inode information using stat(2) */
	if (stat("/sbin", &statbuf) < 0) {
		perror("stat failed");
		exit(1);
	}

	/* NOTE: "madvise() only operates on whole pages, therefore addr must
	 * be page-aligned"
	 * Thus we don't use malloc(), use posix_memalign() !
	 * sbuf = malloc(NUM); // malloc() doesn't guarantee page alignment..
	 * int posix_memalign(void **memptr, size_t alignment, size_t size);
	 */
	posix_memalign(&sbuf, (size_t)pgsz, NUM);
	if (!sbuf) {
		fprintf(stderr, "%s: posix_memalign() failed\n", argv[0]);
		exit(1);
	}

	if (!show_secret) {
		// int madvise(void addr[.length], size_t length, int advice);
		if (madvise(sbuf, (size_t)pgsz, MADV_DONTDUMP) < 0) {
			perror("madvise() failed");
			exit(1);
		}
	}

	/*
	 * strncpy(sbuf, "XECRETXECRET", NUM);
	 * if we write in the 'secret' as above, it shows up as a const text
	 * string in the core dump.. which makes it unrealistic.
	 * Rather, we'll set it as the hex value of 'XECRETXECRET'; then it
	 * doesn't show as ASCII text and is thus more 'secure'.
	 *
	 * Still, without the above madvise() call, we *can* access and dump
	 * the sbuf var within GDB, but with the madvise(MADV_DONTDUMP) it
	 * does NOT show up, even within GDB! Which is the whole point of this
	 * exercise.
	 */
	memset(sbuf, 0, pgsz);
	// XECRET in hex
	sprintf(sbuf, "%c%c%c%c%c%c", 0x58, 0x45, 0x43, 0x52, 0x45, 0x54);
	sprintf(sbuf+6, "%c%c%c%c%c%c", 0x57+1, 0x44+1, 0x42+1, 0x51+1, 0x44+1, 0x53+1);
	//free(sbuf); // if we free the buffer, it's usually gone!

	/*
	 * CAUSE a DELIBERATE CRASH and thus a CORE DUMP!
	 * (the bug: ctime() param should be passed as an address)
	 * We assume you have enabled coredump and have set the resource
	 * limit RLIMIT_CORE to a non-zero value or to 'unlimited'
	 * Bash:
	 *   ulimit -c unlimited
	 * 
	 * Lets print the foll reg the file object:
	 *  inode #, size in bytes, modification time
	 *  uid, gid
	 *  optimal block size, # of blocks
	 */
	printf("%s:\n"
	       " inode number: %d : size (bytes): %d : mtime: %s\n"
	       " uid: %d gid: %d\n"
	       " blksize: %d blk count: %d\n",
	       argv[1], statbuf.st_ino,
	       statbuf.st_size,
	       ctime(statbuf.st_mtime), // BUG: will cause a segfault and coredump (when enabled)
	       statbuf.st_uid, statbuf.st_gid,
	       statbuf.st_blksize, statbuf.st_blocks);

	exit(0);
}
