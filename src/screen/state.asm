; terminal/size
extern term_get_size
extern term.ws_row
extern term.ws_col

; util/ascii
extern num_to_ascii


%include "src/util/vector.mac"


struc cell
  .text       resb 4
  .background resb 3
  .foreground resb 3
  .width      resb 1
  .flags      resb 1
endstruc

DEFINE_VECTOR screen, cell_size


section .bss
screen resb vector_size


section .text


global setup_screen
setup_screen:
  push rbp
  mov  rbp, rsp

  sub rsp, 32

  ; buffer size
  call  term_get_size
  movzx rax, word [term.ws_row]
  movzx rdx, word [term.ws_col]
  mul   rdx

  ; init vector with buffer size preallocated
  mov  rdi, screen
  mov  rsi, rax
  call screen_init

  ; vector capacity in ascii
  mov  rdi, qword [screen + vector.capacity]
  mov  rsi, 0
  lea  rdx, [rbp - 20]
  call num_to_ascii
  mov  qword [rbp - 28], rax

  ; print capacity
  mov rax, 1 ; write
  mov rdi, 1 ; stdout
  lea rsi, [rbp - 20]
  mov rdx, qword [rbp - 28]
  syscall

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

