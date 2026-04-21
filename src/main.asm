; terminal/alternate-buffer
extern enableAlternateBuffer
extern disableAlternateBuffer

; signal/set-handler
extern setSignalHandler

; util/ascii
extern numToASCII


section .data

specialNumberASCII db 20 dup(0x30)

ENDL    equ 0x0A

message db  ENDL, "Recieved Ctrl + C", ENDL, "Press again to exit", ENDL, "Special Number: "
length  equ $ - message

interruptFlag  db 0
interruptCount db 0


section .text

align 16
global _start
_start:
  mov rdi, 2 ; SIGINT
  mov rsi, interruptHandler
  call setSignalHandler

  call enableAlternateBuffer

  .infiniteLoop:
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
exit:
  call disableAlternateBuffer

  ; exit with code 0
  mov rax, 60
  mov edi, 0
  syscall

  hlt

