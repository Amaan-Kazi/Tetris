; terminal/alternate-buffer
extern enableAlternateBuffer
extern disableAlternateBuffer

; screen/buffer
extern setupWindowChangeHandler

; screen/main-menu/main-menu
extern mainMenu


section .text

align 16
global _start
_start:
  call enableAlternateBuffer
  
  call mainMenu

  call disableAlternateBuffer

  ; Exit with code 0
  mov rax, 60
  mov edi, 0
  syscall

