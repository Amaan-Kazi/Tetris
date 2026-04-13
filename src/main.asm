section .text

global _start
_start:
  ; Exit
  mov rax, 60
  mov edi, 0
  syscall
  hlt

