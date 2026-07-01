%ifdef PLATFORM_WINDOWS
  extern CreateFileA
%else
  %include "src/os/syscall-number.mac"
%endif

%include "src/os/open-flags.mac"


section .text

; arg1 rdi = char* filename [must be null terminated]
; arg2 rsi = open flags
global open
open:
  push rbp
  mov  rbp, rsp

  mov r10, rdi
  mov r11, rsi

%ifdef PLATFORM_WINDOWS
  sub rsp, 64

  mov rdx, 0

  test r11, OPEN_READ
  jz  .write
  or   rdx, 0x80000000 ; GENERIC_READ

  .write:
  test r11, OPEN_WRITE
  jz  .read_write_handled
  or   rdx, 0x40000000 ; GENERIC_WRITE

  .read_write_handled:

  test r11, OPEN_APPEND
  jz  .append_handled
  ; or   rdx, FILE_APPEND_DATA ; GENERIC_WRITE includes FILE_APPEND_DATA

  .append_handled:

  ; by default, only open if existing
  mov qword [rsp + 32], 3 ; OPEN_EXISTING

  mov rsi, r11
  and rsi, OPEN_CREATE | OPEN_TRUNCATE
  cmp rsi, OPEN_TRUNCATE
  jne .open_always
  mov qword [rsp + 32], 5 ; TRUNCATE_EXISTING
  jmp .creation_handled

  .open_always:
  mov rsi, r11
  and rsi, OPEN_CREATE | OPEN_TRUNCATE
  cmp rsi, OPEN_CREATE
  jne .create_always
  mov qword [rsp + 32], 4 ; OPEN_ALWAYS
  jmp .creation_handled

  .create_always:
  mov rsi, r11
  and rsi, OPEN_CREATE | OPEN_TRUNCATE
  cmp rsi, OPEN_CREATE | OPEN_TRUNCATE
  jne .creation_handled
  mov qword [rsp + 32], 2 ; CREATE_ALWAYS

  .creation_handled:

  mov rcx, r10              ; LPCSTR                 lpFileName
  ; rdx already set         ; DWORD                  dwDesiredAccess
  mov r8, 0x00000001        ; DWORD                  dwShareMode           = FILE_SHARE_READ
  mov r9, 0                 ; LPSECURITY_ATTRIBUTES  lpSecurityAttributes  [optional]
  ; arg5 already set        ; DWORD                  dwCreationDispotion
  mov qword [rsp + 40], 128 ; DWORD                  dwFlagsAndAttributes  = FILE_ATTRIBUTE_NORMAL
  mov qword [rsp + 48], 0   ; HANDLE                 hTemplateFile
  call CreateFileA
%else
  mov rsi, 0

  ; O_RDONLY is 0 meaning read only by default

  test r11, OPEN_WRITE
  jz  .read_write_handled
  mov  rsi, 1 ; O_WRONLY

  test r11, OPEN_READ
  jz  .read_write_handled
  mov  rsi, 2 ; O_RDWR

  .read_write_handled:

  test r11, OPEN_APPEND
  jz  .create
  or   rsi, 0x400 ; O_APPEND

  .create:
  test r11, OPEN_CREATE
  jz  .truncate
  or   rsi, 0x040 ; O_CREAT

  .truncate:
  test r11, OPEN_TRUNCATE
  jz  .flags_handled
  or   rsi, 0x200 ; O_TRUNC

  .flags_handled:

  mov rax, SYS_open
  mov rdi, r10   ; filename
  ; rsi already has flags
  mov rdx, 0o644 ; mode = rw-r--r--
  syscall
%endif

  mov rsp, rbp
  pop rbp
  ret

