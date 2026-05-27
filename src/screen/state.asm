; terminal/size
extern term_get_size
extern term.ws_row
extern term.ws_col

; util/ascii
extern num_to_ascii

; screen/generate-output
extern generate_rect

; main
extern debug_mode
extern debug_fd

; terminal/alternate-buffer
extern disable_alt_buffer


%include "src/util/vector.mac"

%include "src/struct/cell.mac"
%include "src/struct/term-state.mac"
%include "src/struct/rect.mac"

DEFINE_VECTOR screen, cell_size
DEFINE_VECTOR output_buffer, 1


section .bss

global screen
screen resb vector_size

global output_buffer
global output_buffer_push
output_buffer resb vector_size


section .data

global current_term_state
current_term_state: istruc term_state
  at term_state.background, db 0, 0, 0
  at term_state.foreground, db 0, 0, 0
  at term_state.cursorx,    dw 0
  at term_state.cursory,    dw 0
  at term_state.flags,      db 0
iend

stdout_error db "ERROR: stdout is not a terminal", 0x0A
stdout_error_length equ $ - stdout_error


section .text


global setup_screen
setup_screen:
  push rbp
  mov  rbp, rsp

  sub rsp, 16

  ; buffer size
  call term_get_size

  cmp rax, 0
  je .stdout_is_term

  call disable_alt_buffer

  mov rax, 1 ; SYS_write
  mov rdi, 2 ; stderr
  mov rsi, stdout_error
  mov rdx, stdout_error_length
  syscall

  ; Exit with error
  mov rax, 60
  mov rdi, 1
  syscall

  .stdout_is_term:

  movzx rax, word [term.ws_row]
  movzx rdx, word [term.ws_col]
  mul   rdx

  ; init vector with buffer size preallocated
  mov  rdi, screen
  mov  rsi, rax
  call screen_init

  ; init output buffer with a page preallolcated
  mov  rdi, output_buffer
  mov  rsi, 4096
  call output_buffer_init

  ; render test
  mov rdi, qword [screen + vector.data]
  mov rax, 10
  mov rdx, cell_size
  mul rdx

  mov byte [rdi + rax + cell.text], 'H'
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'e'
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'l'
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'l'
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'o'

  mov word [rbp - 8 + rect.x1], 10
  mov word [rbp - 8 + rect.y1], 0
  mov word [rbp - 8 + rect.x2], 14
  mov word [rbp - 8 + rect.y2], 0

  lea rdi, [rbp - 8]
  call generate_rect

  mov rax, 1
  mov rdi, 1
  mov rsi, qword [output_buffer + vector.data]
  mov rdx, qword [output_buffer + vector.size]
  syscall

  cmp byte [debug_mode], 1
  jne .exit

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, qword [output_buffer + vector.data]
  mov rdx, qword [output_buffer + vector.size]
  syscall

  .exit:
  mov rsp, rbp
  pop rbp
  ret


global screen_change_handler
screen_change_handler:
  push rbp
  mov  rbp, rsp

  sub rsp, 32
  mov byte [rbp - 21], 0x0A
  mov byte [rbp - 22], 0x0A

  ; buffer size
  call  term_get_size
  movzx rax, word [term.ws_row]
  movzx rdx, word [term.ws_col]
  mul   rdx

  ; reserve buffer size in vector
  mov  rdi, screen
  mov  rsi, rax
  call screen_reserve

  ; vector capacity in ascii
  mov  rdi, qword [screen + vector.capacity]
  mov  rsi, 0
  lea  rdx, [rbp - 20]
  call num_to_ascii
  mov  qword [rbp - 30], rax

  ; print capacity
  mov rax, 1 ; write
  mov rdi, 1 ; stdout
  lea rsi, [rbp - 22]
  mov rdx, qword [rbp - 30]
  add rdx, 2
  syscall

  mov rsp, rbp
  pop rbp
  ret

