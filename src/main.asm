; terminal/alternate-buffer
extern enableAlternateBuffer
extern disableAlternateBuffer

; terminal/size
extern getTerminalSize
extern winsize.ws_row
extern winsize.ws_col

; signal/set-handler
extern setSignalHandler

; util/ascii
extern numToASCII


section .bss

specialNumberASCII resb 20

rowsASCII          resb 20
rowsASCIILength    resb 1

colsASCII          resb 20
colsASCIILength    resb 1


section .data

ENDL    equ 0x0A

message db  ENDL, "Recieved Ctrl + C", ENDL, "Press again to exit", ENDL, "Special Number: "
length  equ $ - message

windowMessage       db ENDL, ENDL, "Window Changed:", ENDL
windowMessageLength equ $ - windowMessage

rowsMessage       db  "Rows: "
rowsMessageLength equ $ - rowsMessage

colsMessage       db  ENDL, "Columns: "
colsMessageLength equ $ - colsMessage

windowChangeFlag db 0
interruptFlag    db 0
interruptCount   db 0


section .text

align 16
global _start
_start:
  ; Set Interrupt Handler
  mov  rdi, 2 ; SIGINT
  mov  rsi, interruptHandler
  call setSignalHandler

  ; Set Window Handler
  mov  rdi, 28 ; SIGWINCH
  mov  rsi, windowChangeHandler
  call setSignalHandler

  call enableAlternateBuffer

  .infiniteLoop:
    cmp byte [windowChangeFlag], 0
    je .windowNotChanged

    ; reset flag
    mov byte [windowChangeFlag], 0

    call getTerminalSize

    ; Print window changed message
    mov rax, 1 ; write
    mov edi, 1 ; stdout
    mov rsi, windowMessage
    mov rdx, windowMessageLength
    syscall

    ; convert rows and cols
    movzx rdi, word [winsize.ws_row]
    mov   rsi, 0
    mov   rdx, rowsASCII
    call  numToASCII
    mov   byte [rowsASCIILength], al

    movzx rdi, word [winsize.ws_col]
    mov   rsi, 0
    mov   rdx, colsASCII
    call  numToASCII
    mov   byte [colsASCIILength], al

    ; Print rows
    mov rax, 1 ; write
    mov edi, 1 ; stdout
    mov rsi, rowsMessage
    mov rdx, rowsMessageLength
    syscall
    mov rax, 1 ; write
    mov edi, 1 ; stdout
    mov rsi, rowsASCII
    movzx rdx, byte [rowsASCIILength]
    syscall

    ; Print cols
    mov rax, 1 ; write
    mov edi, 1 ; stdout
    mov rsi, colsMessage
    mov rdx, colsMessageLength
    syscall
    mov rax, 1 ; write
    mov edi, 1 ; stdout
    mov rsi, colsASCII
    movzx rdx, byte [colsASCIILength]
    syscall


    .windowNotChanged:
    cmp byte [interruptFlag], 0
    je .infiniteLoop

    ; reset flag
    mov byte [interruptFlag], 0

    ; Print message
    mov rax, 1 ; write
    mov edi, 1 ; stdout
    mov rsi, message
    mov rdx, length
    syscall

    ; convert number to ASCII
    mov rdi, -12345
    mov rsi, 1
    mov rdx, specialNumberASCII
    call numToASCII

    ; Print special number
    mov rdx, rax
    mov rax, 1
    mov edi, 1
    mov rsi, specialNumberASCII
    syscall

    cmp byte [interruptCount], 1
    je exit
    inc byte [interruptCount]

    jmp .infiniteLoop

  .end:
    call exit


align 16
interruptHandler:
  mov byte [interruptFlag], 1
  ret

align 16
windowChangeHandler:
  mov byte [windowChangeFlag], 1
  ret


align 16
exit:
  call disableAlternateBuffer

  ; exit with code 0
  mov rax, 60
  mov edi, 0
  syscall

  hlt

