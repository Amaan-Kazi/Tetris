default rel

%ifdef PLATFORM_WINDOWS
  extern GetStdHandle
%endif


section .data

global STDIN
STDIN  dq 0

global STDOUT
STDOUT dq 1

global STDERR
STDERR dq 2


section .text

global get_std_fd
get_std_fd:
  push rbp
  mov  rbp, rsp

%ifdef PLATFORM_WINDOWS
  sub rsp, 32 ; shadow space

  ; STDIN
  mov  rcx, 4294967286 ; CONIN$ ((DWORD)-10)
  call GetStdHandle
  mov  qword [STDIN], rax

  ; STDOUT
  mov  rcx, 4294967285 ; CONOUT$ ((DWORD)-11)
  call GetStdHandle
  mov  qword [STDOUT], rax

  ; STDERR
  mov  rcx, 4294967284 ; CONOUT$ ((DWORD)-12)
  call GetStdHandle
  mov  qword [STDERR], rax
%else
  mov qword [STDIN],  0
  mov qword [STDOUT], 1
  mov qword [STDERR], 2
%endif

  mov rsp, rbp
  pop rbp
  ret

