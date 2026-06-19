; main
extern debug_mode
extern debug_fd

; util/ascii
extern num_to_ascii


struc timespec
  .tv_sec  resb 8
  .tv_nsec resb 8
endstruc


section .data

global tsc_ticks_per_ns
global tsc_ticks_per_us
global tsc_ticks_per_ms
global tsc_ticks_per_s

global tsc_ns_per_tick
global tsc_us_per_tick
global tsc_ms_per_tick
global tsc_s_per_tick

tsc_ticks_per_ns dq 0
tsc_ticks_per_us dq 0
tsc_ticks_per_ms dq 0
tsc_ticks_per_s  dq 0 ; aka frequency

tsc_ns_per_tick dq 0
tsc_us_per_tick dq 0
tsc_ms_per_tick dq 0
tsc_s_per_tick  dq 0

msg1     db "Ticks: "
msg1_len equ $ - msg1

msg2     db 0x0A, "Time:  "
msg2_len equ $ - msg2

msg3     db 0x0A, 0x0A, "ticks/ns: "
msg3_len equ $ - msg3

msg4     db 0x0A, "ticks/us: "
msg4_len equ $ - msg4

msg5     db 0x0A, "ticks/ms: "
msg5_len equ $ - msg5

msg6     db 0x0A, "ticks/s:  "
msg6_len equ $ - msg6

msg7     db 0x0A, 0x0A, "ns/tick: "
msg7_len equ $ - msg7

msg8     db 0x0A, "us/tick: "
msg8_len equ $ - msg8

msg9     db 0x0A, "ms/tick: "
msg9_len equ $ - msg9

msg10     db 0x0A, "s/tick:  "
msg10_len equ $ - msg10

msg11     db 0x0A, 0x0A
msg11_len equ $ - msg11


section .text

; calibrates tsc_frequency by sleeping for 20ms and measure monotonic clock time against tsc time
global calibrate_tsc_frequency
calibrate_tsc_frequency:
  push rbp
  mov  rbp, rsp

  sub rsp, 96

  ; get monotonic clock time
  mov rax, 228 ; SYS_clock_gettime
  mov rdi, 4   ; CLOCK_MONOTONIC_RAW
  lea rsi, [rbp - 32]
  syscall

  ; get tsc time
  mfence
  lfence
  rdtsc

  ; combine edx and eax rdx
  shl rdx, 32
  or  rax, rdx
  mov qword [rbp - 8], rax

  ; sleep for 20ms
  mov qword [rbp - 64 + timespec.tv_nsec], 20 * 1000000 ; 20ms
  mov rax, 35         ; SYS_nanosleep
  lea rdi, [rbp - 64] ; requested time
  mov rsi, 0          ; remaining time = NULL
  syscall

  ; get monotonic clock time
  mov rax, 228 ; SYS_clock_gettime
  mov rdi, 4   ; CLOCK_MONOTONIC_RAW
  lea rsi, [rbp - 48]
  syscall

  ; get tsc
  rdtscp
  lfence

  ; combine edx and eax into rdx
  shl rdx, 32
  or  rax, rdx
  mov qword [rbp - 16], rax

  ; measure tsc
  mov rax,  qword [rbp - 8]
  sub qword [rbp - 16], rax

  ; convert seconds to nanoseconds and add
  mov rax, qword [rbp - 32 + timespec.tv_sec]
  mov rdx, 1 * 1000000000 ; 1 billion
  mul rdx
  add qword [rbp - 32 + timespec.tv_nsec], rax

  ; convert seconds to nanoseconds and add
  mov rax, qword [rbp - 48 + timespec.tv_sec]
  mov rdx, 1 * 1000000000 ; 1 billion
  mul rdx
  add qword [rbp - 48 + timespec.tv_nsec], rax

  ; measure difference nanoseconds
  mov rax, qword [rbp - 32 + timespec.tv_nsec]
  sub qword [rbp - 48 + timespec.tv_nsec], rax

  ; calculate frequency
  ; frequency = ticks / seconds
  ;           = ticks * 1billion / seconds * 1billion
  ;           = ticks * 1billion / nanoseconds

  mov rax, qword [rbp - 16]
  mov rdx, 1000000000
  mul rdx
  mov rcx, qword [rbp - 48 + timespec.tv_nsec]
  div rcx
  mov qword [tsc_ticks_per_s], rax

  mov rdx, 0
  mov rcx, 1000
  div rcx
  mov qword [tsc_ticks_per_ms], rax

  mov rdx, 0
  mov rcx, 1000
  div rcx
  mov qword [tsc_ticks_per_us], rax

  mov rdx, 0
  mov rcx, 1000
  div rcx
  mov qword [tsc_ticks_per_ns], rax

  ; calculate reciprocals

  mov rdx, 0
  mov rax, qword [rbp - 48 + timespec.tv_nsec]
  mov rcx, qword [rbp - 16]
  div rcx
  mov qword [tsc_ns_per_tick], rax

  mov rdx, 0
  mov rcx, 1000
  div rcx
  mov qword [tsc_us_per_tick], rax

  mov rdx, 0
  mov rcx, 1000
  div rcx
  mov qword [tsc_ms_per_tick], rax

  mov rdx, 0
  mov rcx, 1000
  div rcx
  mov qword [tsc_s_per_tick], rax

  ; if debug_mode then write frequency and timing to debug file
  cmp byte [debug_mode], 1
  jne .exit

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg1
  mov rdx, msg1_len
  syscall

  mov rdi, qword [rbp - 16]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg2
  mov rdx, msg2_len
  syscall

  mov rdi, qword [rbp - 48 + timespec.tv_nsec]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg3
  mov rdx, msg3_len
  syscall

  mov rdi, qword [tsc_ticks_per_ns]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg4
  mov rdx, msg4_len
  syscall

  mov rdi, qword [tsc_ticks_per_us]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg5
  mov rdx, msg5_len
  syscall

  mov rdi, qword [tsc_ticks_per_ms]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg6
  mov rdx, msg6_len
  syscall

  mov rdi, qword [tsc_ticks_per_s]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg7
  mov rdx, msg7_len
  syscall

  mov rdi, qword [tsc_ns_per_tick]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg8
  mov rdx, msg8_len
  syscall

  mov rdi, qword [tsc_us_per_tick]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg9
  mov rdx, msg9_len
  syscall

  mov rdi, qword [tsc_ms_per_tick]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg10
  mov rdx, msg10_len
  syscall

  mov rdi, qword [tsc_s_per_tick]
  mov rsi, 0
  lea rdx, [rbp - 96]
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, qword [debug_fd]
  lea rsi, [rbp - 96]
  syscall

  mov rax, 1
  mov rdi, qword [debug_fd]
  mov rsi, msg11
  mov rdx, msg11_len
  syscall

  .exit:
  mov rsp, rbp
  pop rbp
  ret

