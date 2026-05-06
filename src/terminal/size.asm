; https://www.man7.org/linux/man-pages/man2/TIOCGWINSZ.2const.html
global term
global term.ws_row
global term.ws_col


section .bss

align 2
term:
  .ws_row    resb 2
  .ws_col    resb 2
  .ws_xpixel resb 2 ; unused
  .ws_ypixel resb 2 ; unused


section .text

; updates the global winsize
global term_get_size:
term_get_size:
  push rbp
  mov  rbp, rsp

  mov rax, 16      ; ioctl
  mov rdi, 1       ; fd  = stdout
  mov rsi, 0x5413  ; cmd = TIOCGWINSZ
  mov rdx, term
  syscall

  ; mov rax, qword [winsize] ; return entire winsize in 64bit register
  mov rsp, rbp
  pop rbp
  ret

