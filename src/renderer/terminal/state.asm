default rel

; renderer/terminal/size
extern term_get_size
extern term.ws_row
extern term.ws_col

; util/ascii
extern num_to_ascii

; renderer/terminal/generate-output
extern generate_rect

; main
extern debug_mode
extern debug_fd

; renderer/terminal/alternate-buffer
extern disable_alt_buffer

; renderer/terminal/reset-screen
extern reset_screen

; os/exit
extern exit


%include "src/util/vector.mac"

%include "src/renderer/terminal/cell/cell.mac"
%include "src/renderer/terminal/term-state.mac"
%include "src/renderer/terminal/rect.mac"
%include "src/renderer/terminal/cell/color.mac"
%include "src/renderer/terminal/cell/flags.mac"

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
  at term_state.cursorx,        dw 0
  at term_state.cursory,        dw 0

  at term_state.background,     db 0, 0, 0
  at term_state.foreground,     db 0, 0, 0
  at term_state.underline,      db 0, 0, 0

  at term_state.flags,          db 0
  at term_state.underline_type, db 0
  at term_state.padding1,       db 0
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
  lea rsi, [stdout_error]
  mov rdx, stdout_error_length
  syscall

  ; Exit with error
  mov  rdi, 1
  call exit

  .stdout_is_term:

  movzx rax, word [term.ws_row]
  movzx rdx, word [term.ws_col]
  mul   rdx

  ; init vector with buffer size preallocated
  lea  rdi, [screen]
  mov  rsi, rax
  call screen_init

  ; init output buffer with a page preallolcated
  lea  rdi, [output_buffer]
  mov  rsi, 4096
  call output_buffer_init

  call reset_screen

  ; render test
  mov rdi, qword [screen + vector.data]
  mov rax, 10
  mov rdx, cell_size
  mul rdx

  mov byte [rdi + rax + cell.text], 'H'
  mov byte [rdi + rax + cell.foreground + color.r], 255
  mov byte [rdi + rax + cell.underline_type], CELL_CURLY_UNDERLINE
  mov byte [rdi + rax + cell.underline + color.g], 100
  mov byte [rdi + rax + cell.flags], CELL_BOLD
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'e'
  mov byte [rdi + rax + cell.foreground + color.r], 255
  mov byte [rdi + rax + cell.underline_type], CELL_CURLY_UNDERLINE
  mov byte [rdi + rax + cell.underline + color.g], 100
  mov byte [rdi + rax + cell.flags], CELL_DIM
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'l'
  mov byte [rdi + rax + cell.foreground + color.g], 255
  mov byte [rdi + rax + cell.underline_type], CELL_DOTTED_UNDERLINE
  mov byte [rdi + rax + cell.flags], CELL_DIM | CELL_BOLD
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'l'
  mov byte [rdi + rax + cell.foreground + color.g], 255
  mov byte [rdi + rax + cell.underline_type], CELL_DOTTED_UNDERLINE
  mov byte [rdi + rax + cell.underline + color.b], 100
  add rax, cell_size
  mov byte [rdi + rax + cell.text + 0], 0b11100010
  mov byte [rdi + rax + cell.text + 1], 0b10101101
  mov byte [rdi + rax + cell.text + 2], 0b10010000
  mov byte [rdi + rax + cell.foreground + color.g], 255
  mov byte [rdi + rax + cell.underline_type], CELL_DOTTED_UNDERLINE
  mov byte [rdi + rax + cell.underline + color.b], 100
  mov byte [rdi + rax + cell.width], CELL_WIDTH_2
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'x' ; shouldnt appear
  mov byte [rdi + rax + cell.foreground + color.r], 255
  mov byte [rdi + rax + cell.width], CELL_WIDTH_0
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'o'
  mov byte [rdi + rax + cell.foreground + color.r], 255
  mov byte [rdi + rax + cell.underline + color.r], 100 ; should be ignored since no underline

  ; (y * width + x) * cell_size    [y is 1 so not multiplying]
  mov   rax, cell_size
  movzx rdx, word [term.ws_col]
  add   rdx, 10
  mul   rdx

  mov byte [rdi + rax + cell.text], 'W'
  mov byte [rdi + rax + cell.foreground + color.b], 255
  mov byte [rdi + rax + cell.underline_type], CELL_DASHED_UNDERLINE
  mov byte [rdi + rax + cell.flags], CELL_BLINK | CELL_STRIKETHROUGH
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'o'
  mov byte [rdi + rax + cell.foreground + color.b], 255
  mov byte [rdi + rax + cell.underline_type], CELL_DASHED_UNDERLINE
  mov byte [rdi + rax + cell.flags], CELL_BLINK | CELL_STRIKETHROUGH
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'r'
  mov byte [rdi + rax + cell.foreground + color.b], 255
  mov byte [rdi + rax + cell.underline_type], CELL_SINGLE_UNDERLINE
  mov byte [rdi + rax + cell.flags], CELL_INVERSE | CELL_ITALIC | CELL_HIDDEN
  add rax, cell_size
  mov byte [rdi + rax + cell.text], 'l'
  mov byte [rdi + rax + cell.background + color.r], 45
  mov byte [rdi + rax + cell.background + color.g], 148
  mov byte [rdi + rax + cell.background + color.b], 76
  mov byte [rdi + rax + cell.underline_type], CELL_SINGLE_UNDERLINE
  mov byte [rdi + rax + cell.flags], CELL_BOLD| CELL_STRIKETHROUGH | CELL_ITALIC
  add rax, cell_size
  mov byte [rdi + rax + cell.text + 0], 0b11110000
  mov byte [rdi + rax + cell.text + 1], 0b10011111
  mov byte [rdi + rax + cell.text + 2], 0b10011000
  mov byte [rdi + rax + cell.text + 3], 0b10000000
  mov byte [rdi + rax + cell.background + color.r], 45
  mov byte [rdi + rax + cell.background + color.g], 148
  mov byte [rdi + rax + cell.background + color.b], 76
  mov byte [rdi + rax + cell.width], CELL_WIDTH_2
  add rax, cell_size
  mov byte [rdi + rax + cell.foreground + color.r], 255
  mov byte [rdi + rax + cell.text], 'x' ; shouldnt appear
  mov byte [rdi + rax + cell.width], CELL_WIDTH_0
  add rax, cell_size
  mov byte [rdi + rax + cell.foreground + color.r], 255
  mov byte [rdi + rax + cell.text], 'd'

  ; last col (ws_col - 1) of first row (0)
  movzx rax, word [term.ws_col]
  dec rax
  mov rdx, cell_size
  mul rdx

  mov byte [rdi + rax + cell.text], 'h'
  mov byte [rdi + rax + cell.foreground + color.r], 255

  ; (y * width + x) * cell_size
  ; (1 * width + (width - 1)) * cell_size
  ; (width + width - 1) * cell_size
  ; (2 * width - 1) * cell_size
  movzx rax, word [term.ws_col] ; y * width
  shl rax, 1
  dec rax
  mov rdx, cell_size
  mul rdx

  mov byte [rdi + rax + cell.text], 'i'
  mov byte [rdi + rax + cell.foreground + color.r], 255

  mov word [rbp - 8 + rect.x1], 10
  mov word [rbp - 8 + rect.y1], 0
  mov word [rbp - 8 + rect.x2], 16
  mov word [rbp - 8 + rect.y2], 1

  lea rdi, [rbp - 8]
  call generate_rect

  mov ax, word [term.ws_col]
  dec ax

  mov word [rbp - 8 + rect.x1], ax
  mov word [rbp - 8 + rect.y1], 0
  mov word [rbp - 8 + rect.x2], ax
  mov word [rbp - 8 + rect.y2], 1

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
  lea  rdi, [screen]
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

