; signal/set-handler
extern setSignalHandler

; screen/buffer
extern setupScreenBuffer
extern windowChanged


section .data

SIGWINCH         equ 28
SIGINT           equ 2
windowChangeFlag db  0
interruptFlag    db  0


section .text

align 16
global mainMenu
mainMenu:
  ; Set Interrupt Handler
  mov  rdi, SIGINT
  mov  rsi, interruptHandler
  call setSignalHandler

  ; Set Window Handler
  mov  rdi, SIGWINCH
  mov  rsi, windowChangeHandler
  call setSignalHandler

  .infiniteLoop:
    ; Exit on Ctrl + C
    cmp byte [interruptFlag], 1
    je .exit

    cmp byte [windowChangeFlag], 0
    je .infiniteLoop

    ; Reset Flag
    mov byte [windowChangeFlag], 0

    call windowChanged

    jmp .infiniteLoop

  .exit:
  ret


align 16
windowChangeHandler:
  mov byte [windowChangeFlag], 1
  ret

align 16
interruptHandler:
  mov byte [interruptFlag], 1
  ret


