default rel

; renderer/terminal/alternate-buffer
extern enable_alt_buffer
extern disable_alt_buffer

; scene/main-menu/main-menu
extern main_menu

; util/time
extern calibrate_tsc_frequency


section .data
arg_debug db "--debug", 0x0 ; \0

global debug_mode
debug_mode db 0

global debug_file
debug_file db "debug.log", 0x0

align 8
global debug_fd
debug_fd dq -1

debug_file_error db "ERROR: failed to open debug file", 0x0A
debug_file_error_length equ $ - debug_file_error


section .text

global _start
_start:
  ; argc
  mov rdx, qword [rsp]

  cmp rdx, 1
  jbe .arg_check_complete

  lea rdi, [arg_debug]
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

  mov rax, 2            ; SYS_open
  lea rdi, [debug_file] ; filename
  mov rsi, 0x641        ; flags = O_APPEND (0x400) | O_TRUNC (0x200) | O_CREAT (0x040) | O_WRONLY (0x001)
  mov rdx, 0o644        ; mode
  syscall

  cmp rax, 0
  jge .debug_open_success

  mov rax, 1 ; SYS_write
  mov rdi, 2 ; stderr
  lea rsi, [debug_file_error]
  mov rdx, debug_file_error_length
  syscall

  ; Exit with error
  mov rax, 60
  mov rdi, 1
  syscall

  .debug_open_success:
  mov qword [debug_fd], rax
  mov byte [debug_mode], 1


  .arg_check_complete:

  call calibrate_tsc_frequency

  call enable_alt_buffer

  call main_menu

  call disable_alt_buffer


  ; Exit with code 0
  mov rax, 60
  mov edi, 0
  syscall

