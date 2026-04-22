; https://www.man7.org/linux/man-pages/man2/TIOCGWINSZ.2const.html
global winsize
global winsize.ws_row
global winsize.ws_col
global winsize.ws_xpixel
global winsize.ws_ypixel

section .bss

align 2
winsize:
  .ws_row    resb 2
  .ws_col    resb 2
  .ws_xpixel resb 2 ; unused
  .ws_ypixel resb 2 ; unused


section .text

; Returns the terminal size in rax
; first 2 bytes: rows
; next  2 bytes: cols
; next  2 bytes: x pixels (unused)
; last  2 bytes: y pixels (unused)
align 16
global getTerminalSize
getTerminalSize:
  mov rax, 16      ; ioctl
  mov rdi, 1       ; fd  = stdout
  mov rsi, 0x5413  ; cmd = TIOCGWINSZ
  mov rdx, winsize
  syscall

  ; mov rax, qword [winsize] ; return entire winsize in 64bit register
  ret

