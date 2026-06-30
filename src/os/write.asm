default rel

%ifdef PLATFORM_WINDOWS
  extern WriteFile
%else
  %include "src/os/syscall-number.mac"
%endif


section .text

; arg1 rdi = fd
; arg2 rsi = &buffer
; arg3 rdx = count
global write
write:
  push rbp
  mov  rbp, rsp

%ifdef PLATFORM_WINDOWS
  sub rsp, 48

  ; rsp + 0  .. 32 = shadow space
  ; rsp + 32 .. 40 = function parameter 5
  ; rsp + 40 .. 44 = 4 bytes for getting back the number of bytes written

  mov  rcx,   rdi          ; HANDLE        hFile
  mov  r8,    rdx          ; DWORD         nNumberOfBytesToWrite
  mov  rdx,   rsi          ; LPCVOID       lpBuffer
  lea  r9,   [rsp + 40]    ; LPDWORD       lpNumberOfBytesWritten
  mov  qword [rsp + 32], 0 ; LPOVERLAPPED  lpOverlapped [optional, related to async IO]
  call WriteFile

  cmp rax, 0
  jne .WriteFileNoError

  mov rax, 0
  jmp .exit

  .WriteFileNoError:
  ; return number of bytes written
  movzx rax, dword [rsp + 40]
%else
  mov rax, SYS_write
  ; rdi already has fd
  ; rsi already has buffer
  ; rdx already has count
  syscall
%endif

  .exit:
  mov rsp, rbp
  pop rbp
  ret

