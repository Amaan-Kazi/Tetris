# Signals
Special IPC method that interrupts normal execution temporarily\
Examples:
- SIGINT (Ctrl + C)
- SIGWINCH (Window Size Changed)


## Signal Handler
A function that gets called by the kernel when a specific signal occurs


## [rt_sigaction syscall](https://www.man7.org/linux/man-pages/man2/sigaction.2.html)
Used to set a signal handler for a specified signal

```C
rt_sigaction(
  int                signum,
  struct sigaction   *newAction,
  struct sigaction   *oldAction,
  size_t             sigsetsize  
);
```
On x86_64 Linux Kernel, sigset_t (8 bytes) is different from glibc sigset_t (128 bytes)\
`sigsetsize` should match with kernel size otherwise syscall fails with `EINVAL`


## sigaction struct
```C
struct sigaction {
  void           (*sa_handler)(int);
  unsigned long  sa_flags;
  void           (*sa_restorer)(void);
  sigset_t       sa_mask;
};
```


### sa_handler
The function to be called when that signal occurs


### sa_flags
Flags for portably and explicitly defining behavior of signals\
Flags are OR'ed together (eg. SA_RESTART | SA_RESTORER)

`SA_RESTART` allows restarting some syscalls (like read, write, etc) that may have been interrupted due to the signal
`0x10000000` on Linux, defined in glibc signal.h\
Recommended to be used by default (read [glibc docs](https://sourceware.org/glibc/manual/2.43/html_node/Flags-for-Sigaction.html#Flags-for-sigaction) for details)

`SA_RESTORER` is required to indicate that `sa_restorer` field in the `sigaction` struct contains a pointer to such a function\
`0x04000000` on Linux, defined in glibc/sysdeps/unix/sysv/linux/x86_64/libc_sigaction.c


### sa_mask
Additional `set` of signals to be blocked while handler is executing

It is of type `sigset_t` which may have different sizes on on different platforms\
Each signal is represented with 1 bit\
Size of `sigset_t` in the Linux kernel is 8 bytes\
However size of `sigset_t` on glibc linux is 128 bytes

[glibc docs](https://sourceware.org/glibc/manual/2.43/html_node/Signal-Sets.html) for signal sets:
```txt
You must always initialize the signal set with one of these two functions before using it in any other way.
Don’t try to set all the signals explicitly because the sigset_t object might include some other information (like a version field) that needs to be initialized as well.
(In addition, it’s not wise to put into your program an assumption that the system has no signals aside from the ones you know about.)
```

However we only need an empty set for now\
The implementation of sigemptyset() on Linux simply 0s all bits (might be more complicated on other platforms):
```C
// glibc/sysdeps/unix/sysv/linux/sigsetops.h
// line 49-55, restructured for clarity
static inline void __sigemptyset (sigset_t *set) {
  int count = __NSIG_WORDS;
  while (--count >= 0) set->__val[count] = 0;
}
```


### sa_restorer
A signal trampoline function that must call `rt_sigreturn()` syscall\
Make sure to set SA_RESTORER flag\
Read more in [rt_sigreturn()](https://www.man7.org/linux/man-pages/man2/sigreturn.2.html) man pages

