section .data
; https://en.wikipedia.org/wiki/ANSI_escape_code#Control_Sequence_Introducer_commands
; 0x1b = ESC

enable  db 0x1b, "[?1049h"
length1 equ $ - enable

disable db 0x1b, "[?1049l"
length2 equ $ - disable


section .text

global enableAlternateBuffer
enableAlternateBuffer:
  mov rax, 1 ; write
  mov edi, 1 ; stdout
  mov rsi, enable
  mov rdx, length1
  syscall
  ret

global disableAlternateBuffer
disableAlternateBuffer:
  mov rax, 1 ; write
  mov edi, 1 ; stdout
  mov rsi, disable
  mov rdx, length2
  syscall
  ret

