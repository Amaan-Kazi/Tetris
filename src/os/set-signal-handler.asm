default rel

section .data

align 8
sigaction:
  .sa_handler  dq 0
  .sa_flags    dq 0x0000000014000000 ; SA_RESTART (0x10000000) | SA_RESTORER (0x04000000)
  .sa_restorer dq signal_trampoline
  .sa_mask     dq 0


section .text

global set_signal_handler
set_signal_handler:
  push rbp
  mov  rbp, rsp

  ; arg1 edi = Signal Number, int
  ; arg2 rsi = Signal Handler Function, void*(int)
  mov qword [sigaction.sa_handler], rsi

  ; sys_rt_sigaction
  mov rax, 13
  ; signum is already in edi
  lea rsi, [sigaction]
  mov rdx, 0 ; oldact = NULL
  mov r10, 8 ; sigsetsize = sizeof(kernel_sigset_t)
  syscall

  mov rsp, rbp
  pop rbp
  ret


; This function should only be called by the kernel after returning from a signal handler
; A trampoline is a userspace function that immediately hands back control to kernel
; here via sys_rt_sigreturn
signal_trampoline:
  ; sys_rt_sigreturn
  mov rax, 15
  syscall

  ; rt_sigreturn() syscall is never supposed to return
  ud2

