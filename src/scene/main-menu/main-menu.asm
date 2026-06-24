default rel

; os/set-signal-handler
extern set_signal_handler

; renderer/terminal/state
extern setup_screen
extern screen_change_handler


section .data

SIGWINCH         equ 28
SIGINT           equ 2
size_change_flag db  0
interrupt_flag   db  0


section .text

global main_menu
main_menu:
  push rbp
  mov  rbp, rsp

  call setup_screen

  ; Set Interrupt Handler
  mov  rdi, SIGINT
  lea  rsi, [sigint_handler]
  call set_signal_handler

  ; Set Window Handler
  mov  rdi, SIGWINCH
  lea  rsi, [sigwinch_handler]
  call set_signal_handler

  .infiniteLoop:
    ; Exit on Ctrl + C
    cmp byte [interrupt_flag], 1
    je .exit

    cmp byte [size_change_flag], 0
    je .infiniteLoop

    ; Reset Flag
    mov byte [size_change_flag], 0

    call screen_change_handler

    jmp .infiniteLoop

  .exit:
  mov rsp, rbp
  pop rbp
  ret


sigint_handler:
  mov byte [interrupt_flag], 1
  ret

sigwinch_handler:
  mov byte [size_change_flag], 1
  ret

