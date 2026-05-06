section .data
; https://en.wikipedia.org/wiki/ANSI_escape_code#Control_Sequence_Introducer_commands

ESC     equ 0x1b

enable  db  ESC, "[?1049h"
length1 equ $ - enable

disable db  ESC, "[?1049l"
length2 equ $ - disable


section .text

global enable_alt_buffer
enable_alt_buffer:
  push rbp
  mov  rbp, rsp

  mov rax, 1 ; write
  mov edi, 1 ; stdout
  mov rsi, enable
  mov rdx, length1
  syscall

  mov rsp, rbp
  pop rbp
  ret

global disable_alt_buffer
disable_alt_buffer:
  push rbp
  mov  rbp, rsp

  mov rax, 1 ; write
  mov edi, 1 ; stdout
  mov rsi, disable
  mov rdx, length2
  syscall

  mov rsp, rbp
  pop rbp
  ret

