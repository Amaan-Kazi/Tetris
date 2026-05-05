; terminal/size
extern getTerminalSize
extern winsize.ws_row
extern winsize.ws_col

; util/ascii
extern numToASCII


struc cell
  .background resb 3
  .foreground resb 3
  .text       resb 1
endstruc


section .bss
rowsASCII resb 20
colsASCII resb 20


section .data

SYS_write equ 1
STDOUT    equ 1

ENDL equ 0x0A

windowChangeFlag            db 0
windowChangeMessage1        db ENDL, ENDL, "Rows: "
windowChangeMessage1_length equ $ - windowChangeMessage1
windowChangeMessage2        db ENDL, "Cols: "
windowChangeMessage2_length equ $ - windowChangeMessage2


section .text

align 16
global setupScreenBuffer
setupScreenBuffer:
  call printTerminalSize
  ret


align 16
global windowChanged
windowChanged:
  call printTerminalSize
  ret


align 16
printTerminalSize:
  call getTerminalSize

  ; Print Rows

  mov rax, SYS_write
  mov edi, STDOUT
  mov rsi, windowChangeMessage1
  mov rdx, windowChangeMessage1_length
  syscall

  movzx rdi, word [winsize.ws_row]
  mov   rsi, 0
  mov   rdx, rowsASCII
  call  numToASCII

  mov rdx, rax
  mov rax, SYS_write
  mov edi, STDOUT
  mov rsi, rowsASCII
  syscall

  ; Print Columns

  mov rax, SYS_write
  mov edi, STDOUT
  mov rsi, windowChangeMessage2
  mov rdx, windowChangeMessage2_length
  syscall

  movzx rdi, word [winsize.ws_col]
  mov   rsi, 0
  mov   rdx, colsASCII
  call  numToASCII

  mov rdx, rax
  mov rax, SYS_write
  mov edi, STDOUT
  mov rsi, colsASCII
  syscall

  ret
