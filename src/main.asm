default rel

; renderer/terminal/alternate-buffer
extern enable_alt_buffer
extern disable_alt_buffer

; scene/main-menu/main-menu
extern main_menu

; util/time
extern calibrate_tsc_frequency

; os/std-fd
extern get_std_fd
extern STDOUT
extern STDERR

; os/open
extern open

; os/write
extern write

; os/exit
extern exit

%include "src/os/open-flags.mac"


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

test_msg db "Hello World", 0x0A, "Line 2", 0x0A
test_len equ $ - test_msg


section .text

global _start
_start:

%ifdef PLATFORM_WINDOWS
  ; windows calls _start leaving rsp 8 byte aligned
  ; so subtracting 8 to make it 16 byte aligned
  sub rsp, 8
%endif

; set stdin, stdout and stderr platform agnostically
call get_std_fd

%ifdef PLATFORM_WINDOWS
  lea rdi, [debug_file] ; filename
  mov rsi, OPEN_APPEND | OPEN_TRUNCATE | OPEN_CREATE | OPEN_WRITE
  call open

  mov rdi, rax
  lea rsi, [test_msg]
  mov rdx, test_len
  call write

  mov  rdi, rax
  call exit
%endif

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

  lea rdi, [debug_file] ; filename
  mov rsi, OPEN_APPEND | OPEN_TRUNCATE | OPEN_CREATE | OPEN_WRITE
  call open

  cmp rax, 0
  jge .debug_open_success

  mov  rdi, qword [STDERR]
  lea  rsi, [debug_file_error]
  mov  rdx, debug_file_error_length
  call write

  ; Exit with error
  mov  rdi, 1
  call exit

  .debug_open_success:
  mov qword [debug_fd], rax
  mov byte [debug_mode], 1


  .arg_check_complete:

  call calibrate_tsc_frequency

  call enable_alt_buffer

  call main_menu

  call disable_alt_buffer


  ; Exit with code 0
  mov  rdi, 0
  call exit

