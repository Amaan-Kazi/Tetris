; terminal/alternate-buffer
extern enable_alt_buffer
extern disable_alt_buffer

; screen/main-menu/main-menu
extern main_menu


section .data
arg_debug db "--debug", 0x0 ; \0

global debug_mode
debug_mode db 0


section .text

global _start
_start:
  ; argc
  mov rdx, qword [rsp]

  cmp rdx, 1
  jbe .arg_check_complete

  mov rdi, arg_debug
  mov rsi, [rsp + 16]

  ; check if arg1 is --debug
  .debug_check_loop:
    mov al, byte [rdi]
    mov cl, byte [rsi]

    cmp al, cl
    jne .arg_check_complete

    inc rdi
    inc rsi

    cmp al, 0
  jne .debug_check_loop
  mov byte [debug_mode], 1


  .arg_check_complete:

  call enable_alt_buffer

  call main_menu

  call disable_alt_buffer


  ; Exit with code 0
  mov rax, 60
  mov edi, 0
  syscall

