section .text

; Convert signed or unsigned 64bit number to ASCII string
; ASCII string is in outputBuffer
; Length of string is returned in rax
align 16
global numToASCII
numToASCII:
  ; arg1 rdi = int64 | uint64   num
  ; arg2 rsi = boolean          isSigned
  ; arg3 rdx = char buffer[20]  outputBuffer
  mov r8, rdx
  mov r9, rsi
  mov rax, rdi
  mov r11, 10

  ; counter
  mov rcx, 0

  ; rsi will be used to track whether or not - was prefixed
  mov rsi, 0


  ; If num is unsigned, then it cant be -ve
  cmp r9, 0
  je .conversion

  ; If num is -ve, then first char is -, and convert num to +ve
  cmp rdi, 0
  jns .conversion

  mov byte [r8], '-'
  inc rcx
  neg rdi
  mov rax, rdi
  mov rsi, 1


  .conversion:
    mov rdx, 0
    ; rax already contains the current num
    div r11

    add rdx, 0x30           ; remainder + ASCII 0
    mov byte [r8+rcx], dl
    inc rcx

    ; if quotient is 0, then conversion is over
    cmp rax, 0
  jne .conversion


  ; r9 points to end of string
  mov r9, r8
  add r9, rcx
  dec r9

  ; rsi points to start of string (exclude -)
  add rsi, r8

  .reverse:
    ; swap start and end
    mov r10b, byte [rsi]
    mov r11b, byte [r9]
    mov byte [rsi], r11b
    mov byte [r9],  r10b

    inc rsi
    dec r9

    ; if start >= end, then exit
    cmp rsi, r9
  jl .reverse


  mov rdx, r8
  mov rax, rcx
  ret

