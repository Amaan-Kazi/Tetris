; terminal/alternate-buffer
extern enable_alt_buffer
extern disable_alt_buffer

; screen/main-menu/main-menu
extern main_menu


section .text

global _start
_start:
  call enable_alt_buffer
  
  call main_menu

  call disable_alt_buffer

  ; Exit with code 0
  mov rax, 60
  mov edi, 0
  syscall

