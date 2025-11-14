# memleak detection via the FlameGraph

## Hypothesis:
We write a C program that deliberately leaks approx half the memory it allocs.
The resulting FlameGraph (FG) should be able to 'show' this to us...
(We use our FlemGrapher wrapper: https://github.com/kaiwan/flamegrapher )


## So let's try it!

`make debug`

`flame_grapher.sh -o memleak -c "$(pwd)/memleak_test_dbg"`

... and then view the flamegraph (memleak.svg):
![the flamegraph memleak.svg](https://github.com/kaiwan/L5_user_debug/blob/main/user_mem_debug/memleak/memleak.svg)


## Conclusion
We can now literally 'see' that the width of the ...free() reactangle (__GI___libc_free) is much
less than that of the ...malloc() rectangle (__GI___libc_malloc), proving the fact that we have a
(simple) leakage bug!

### IMPORTANT, please read
One should not jump to conclude that, hey, we can now find all memory leaks via
this 'FlameGraph' approach.. NO! It doesn't always work because real-world leakge
bugs are typically more subtle; the typical example being third party library
APIs that allocate memory under the hood and expect the caller to free it.

## Also, FYI:

* Our trivial test case test1() does NOT show the desired result
- the malloc() and free() APIs don't show up in the FlameGraph!
Why?? The usual reason is lack of symbols (but we have 'em), no frame
pointers - but we run the FG w/ the --call-graph option which takes
care of that !

* So: we require a large sample size and more importantly, some *actual work*
done in the malloc() so as to not have the comiler optimize it away!
This is done in test2()... and it works.

