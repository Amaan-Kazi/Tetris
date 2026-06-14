; screen/state
extern current_term_state

%include "src/struct/term-state.mac"
%include "src/util/cell-flags.mac"


section .data
ESC equ 0x1b

reset_string:
  db ESC, "[1;1H"              ; goto 1,1
  db ESC, "[0m"                ; reset all graphics modes to default
  db ESC, "[48;2;0;0;0m"       ; background black
  db ESC, "[2J"                ; clear screen with current background color
  db ESC, "[38;2;255;255;255m" ; foreground
  db ESC, "[48;2;0;0;0m"       ; background
  db ESC, "[58;2;255;255;255m" ; underline

reset_string_length equ $ - reset_string


section .text

global reset_screen
reset_screen:
  push rbp
  mov  rbp, rsp

  ; reset current_term_state
  mov word [current_term_state + term_state.cursorx], 0
  mov word [current_term_state + term_state.cursory], 0

  mov byte [current_term_state + term_state.background + color.r], 0
  mov byte [current_term_state + term_state.background + color.g], 0
  mov byte [current_term_state + term_state.background + color.b], 0

  mov byte [current_term_state + term_state.foreground + color.r], 255
  mov byte [current_term_state + term_state.foreground + color.g], 255
  mov byte [current_term_state + term_state.foreground + color.b], 255

  mov byte [current_term_state + term_state.underline  + color.r], 255
  mov byte [current_term_state + term_state.underline  + color.g], 255
  mov byte [current_term_state + term_state.underline  + color.b], 255

  mov byte [current_term_state + term_state.flags], 0
  mov byte [current_term_state + term_state.underline_type], CELL_NO_UNDERLINE

  ; print reset_string
  mov rax, 1 ; write
  mov rdi, 1 ; stdout
  mov rsi, reset_string
  mov rdx, reset_string_length
  syscall

  mov rsp, rbp
  pop rbp
  ret

