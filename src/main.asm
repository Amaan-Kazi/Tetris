extern enableAlternateBuffer
extern disableAlternateBuffer

section .data
message db "Hello World", 0x0A ; 0x0A = \n
length  equ $ - message

section .text

global _start
_start:
  call enableAlternateBuffer

  ; Print Hello World
  mov rax, 1 ; write
  mov edi, 1 ; stdout
  mov rsi, message
  mov rdx, length
  syscall

  ; Block and wait for some input
  mov rax, 0 ; read
  mov edi, 0 ; stdin
  mov rsi, message
  mov rdx, length
  syscall

  call disableAlternateBuffer

  ; Exit
  mov rax, 60
  mov edi, 0
  syscall
  hlt

