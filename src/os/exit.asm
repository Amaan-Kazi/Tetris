%ifdef PLATFORM_WINDOWS
  extern ExitProcess
%else
  %include "src/os/syscall-number.mac"
%endif


section .text

; arg1 rdi = uint8, exit code
global exit
exit:
  push rbp
  mov  rbp, rsp

%ifdef PLATFORM_WINDOWS
  sub  rsp, 32 ; shadow space
  mov  rcx, rdi
  call ExitProcess
%else
  mov rax, SYS_exit
  ; rdi already has exit code
  syscall
%endif

  ud2

