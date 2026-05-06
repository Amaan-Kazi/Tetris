; terminal/size
extern term_get_size
extern term.ws_row
extern term.ws_col

; util/ascii
extern num_to_ascii


struc cell
  .background resb 3
  .foreground resb 3
  .text       resb 1
endstruc


section .bss
rows_ascii resb 20
cols_ascii resb 20


section .data

SYS_write equ 1
STDOUT    equ 1

ENDL equ 0x0A

rows_msg        db ENDL, ENDL, "Rows: "
rows_msg_len    equ $ - rows_msg
cols_msg        db ENDL, "Cols: "
cols_msg_len    equ $ - cols_msg


section .text

global setup_buffer
setup_buffer:
  push rbp
  mov  rbp, rsp

  call print_term_size

  mov rsp, rbp
  pop rbp
  ret


global size_change_handler
size_change_handler:
  push rbp
  mov  rbp, rsp

  call print_term_size

  mov rsp, rbp
  pop rbp
  ret


print_term_size:
  push rbp
  mov  rbp, rsp

  call term_get_size

  ; Print Rows

  mov rax, SYS_write
  mov edi, STDOUT
  mov rsi, rows_msg
  mov rdx, rows_msg_len
  syscall

  movzx rdi, word [term.ws_row]
  mov   rsi, 0
  mov   rdx, rows_ascii
  call  num_to_ascii

  mov rdx, rax
  mov rax, SYS_write
  mov edi, STDOUT
  mov rsi, rows_ascii
  syscall

  ; Print Columns

  mov rax, SYS_write
  mov edi, STDOUT
  mov rsi, cols_msg
  mov rdx, cols_msg_len
  syscall

  movzx rdi, word [term.ws_col]
  mov   rsi, 0
  mov   rdx, cols_ascii
  call  num_to_ascii

  mov rdx, rax
  mov rax, SYS_write
  mov edi, STDOUT
  mov rsi, cols_ascii
  syscall

  mov rsp, rbp
  pop rbp
  ret

