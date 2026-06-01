; screen/state
extern screen
extern output_buffer
extern output_buffer_push
extern debug_mode
extern current_term_state

; terminal/size
extern term.ws_col

; util/ascii
extern num_to_ascii


%include "src/util/multi-push-pop.mac"
%include "src/util/vector.mac"

%include "src/struct/cell.mac"
%include "src/struct/rect.mac"
%include "src/struct/term-state.mac"

DEFINE_VECTOR rect_vec, rect_size


section .bss
rect_vec resb vector_size


section .rodata
uint8ASCII: incbin "src/util/uint8.asc", 0, 768


section .text


; arg1 rdi = &rect,   rectangle boundary to generate
global generate_rect
generate_rect:
  push rbp
  multipush rbx, rbx, r12, r13, r14, r15 ; rbx twice to ensure rsp is still 16 byte aligned
  mov rbp, rsp

  mov rbx, rdi

  movzx r12, word [rbx + rect.x1]
  movzx r13, word [rbx + rect.y1]
  movzx r14, word [rbx + rect.x2]
  movzx r15, word [rbx + rect.y2]

  ; row loop (y1 -> y2)
  .rowloop:
    ; reset x1
    movzx r12, word [rbx + rect.x1]

    ; column loop (x1 -> x2)
    .colloop:
      ; convert cell to ansi escape squences
      mov  rdi, r12
      mov  rsi, r13
      call generate_cell

      ; x1++ ; x1 <= x2 then continue looping
      inc r12
      cmp r12, r14
    jle .colloop

    ; y1++ ; y1 <= y2 then continue looping
    inc r13
    cmp r13, r15
  jle .rowloop

  mov rsp, rbp
  multipop r15, r14, r13, r12, rbx, rbx
  pop rbp
  ret


; arg1 rdi = uint16 x
; arg2 rsi = uint16 y
global generate_cell
generate_cell:
  push rbp
  multipush r12, r13, r14, r14
  mov  rbp, rsp

  mov r12, rdi
  mov r13, rsi

  ; y * width + x
  movzx rax, word [term.ws_col]
  mul rsi
  add rax, rdi

  ; array offset = (y * width + x) * cell_size
  mov rdx, cell_size
  mul rdx

  ; save address of the cell
  mov rdi, qword [screen + vector.data]
  add rdi, rax
  mov r14, rdi

  mov rdi, r12
  mov rsi, r13
  call generate_position

  mov rdi, r14
  mov rsi, 0   ; background
  call generate_color

  mov rdi, r14
  mov rsi, 1   ; foreground
  call generate_color

  mov rdi, r14
  call generate_text

  mov rdi, r14
  call generate_flags

  mov rsp, rbp
  multipop r14, r14, r13, r12
  pop rbp
  ret


; arg1 rdi = x
; arg2 rsi = y
generate_position:
  push rbp
  multipush r12, r13
  mov  rbp, rsp

  ; NOTE: all internal representations and comparisions are 0 indexed
  ; only converting to 1 based indexes when generating ANSI escape sequences

  sub rsp, 48
  mov qword [rbp - 8],  rdi
  mov qword [rbp - 16], rsi

  ; check if row has changed
  mov   rdi, current_term_state
  movzx rdi, word [rdi + term_state.cursory]
  cmp   rdi, rsi
  je   .row_equal

  mov rdi, output_buffer
  mov byte [rbp - 48], 0x1b ; ESC
  lea rsi, [rbp - 48]
  call output_buffer_push

  mov rdi, output_buffer
  mov byte [rbp - 48], '['
  lea rsi, [rbp - 48]
  call output_buffer_push

  ; convert y to ascii
  mov rdi, qword [rbp - 16]
  inc rdi
  mov rsi, 0
  lea rdx, [rbp - 36]
  call num_to_ascii

  ; push every byte of ascii y
  mov r13, rax
  mov r12, 0
  .ycopyloop:
    mov rdi, output_buffer
    lea rsi, [rbp - 36 + r12]
    call output_buffer_push

    inc r12
    cmp r12, r13
  jl .ycopyloop

  mov rdi, output_buffer
  mov byte [rbp - 48], ';'
  lea rsi, [rbp - 48]
  call output_buffer_push

  ; convert x to ascii
  mov rdi, qword [rbp - 8]
  inc rdi
  mov rsi, 0
  lea rdx, [rbp - 36]
  call num_to_ascii

  ; push every byte of ascii x
  mov r13, rax
  mov r12, 0
  .xcopyloop:
    mov rdi, output_buffer
    lea rsi, [rbp - 36 + r12]
    call output_buffer_push

    inc r12
    cmp r12, r13
  jl .xcopyloop

  mov rdi, output_buffer
  mov byte [rbp - 48], 'H'
  lea rsi, [rbp - 48]
  call output_buffer_push

  ; update current_term_state
  mov di, word [rbp - 8]
  mov word [current_term_state + term_state.cursorx], di
  mov si, word [rbp - 16]
  mov word [current_term_state + term_state.cursory], si

  jmp .exit

  .row_equal:

  ; check if col has changed
  mov   rdi, current_term_state
  movzx rdi, word [rdi + term_state.cursorx]
  cmp   rdi, qword [rbp - 8]
  je   .exit

  mov rdi, output_buffer
  mov byte [rbp - 48], 0x1b ; ESC
  lea rsi, [rbp - 48]
  call output_buffer_push

  mov rdi, output_buffer
  mov byte [rbp - 48], '['
  lea rsi, [rbp - 48]
  call output_buffer_push

  ; convert x to ascii
  mov rdi, qword [rbp - 8]
  inc rdi
  mov rsi, 0
  lea rdx, [rbp - 36]
  call num_to_ascii

  ; push every byte of ascii x
  mov r13, rax
  mov r12, 0
  .xcopyloop2:
    mov rdi, output_buffer
    lea rsi, [rbp - 36 + r12]
    call output_buffer_push

    inc r12
    cmp r12, r13
  jl .xcopyloop2

  mov rdi, output_buffer
  mov byte [rbp - 48], 'G'
  lea rsi, [rbp - 48]
  call output_buffer_push

  ; update current_term_state
  mov di, word [rbp - 8]
  mov word [current_term_state + term_state.cursorx], di

  .exit:
  mov rsp, rbp
  multipop r13, r12
  pop rbp
  ret


; arg1 rdi = &cell
; arg2 rsi = bool isForeground, 0 to generate background, 1 to generate foreground
generate_color:
  push rbp
  push r12
  mov  rbp, rsp

  sub rsp, 8

  lea r12, [rdi + cell.backgroundr]
  mov rax, term_state.backgroundr
  mov byte [rbp - 2], '4'

  cmp sil, 1
  jne .is_background

  lea r12, [rdi + cell.foregroundr]
  mov rax, term_state.foregroundr
  mov byte [rbp - 2], '3'

  .is_background:

  mov rcx, -1
  mov rdx, 0  ; track if current_term_state was changed

  .cmploop:
    inc rcx
    cmp rcx, 3
    jge .endcmploop

    ; compare current_term_state with cell
    mov sil, byte [r12                      + rcx]
    cmp sil, byte [current_term_state + rax + rcx]
    je .cmploop

    ; update current_term_state
    mov byte [current_term_state + rax + rcx], sil
    mov rdx, 1
  jmp .cmploop

  .endcmploop:

  ; if current_term_state not changed then we can exit
  cmp rdx, 0
  je .exit

  ; ansi escape sequence for changing color

  mov rdi, output_buffer
  mov byte [rbp - 1], 0x1b ; ESC
  lea rsi, [rbp - 1]
  call output_buffer_push

  mov rdi, output_buffer
  mov byte [rbp - 1], '['
  lea rsi, [rbp - 1]
  call output_buffer_push

  mov rdi, output_buffer
  lea rsi, [rbp - 2]
  call output_buffer_push

  mov rdi, output_buffer
  mov byte [rbp - 1], '8'
  lea rsi, [rbp - 1]
  call output_buffer_push

  mov rdi, output_buffer
  mov byte [rbp - 1], ';'
  lea rsi, [rbp - 1]
  call output_buffer_push

  mov rdi, output_buffer
  mov byte [rbp - 1], '2'
  lea rsi, [rbp - 1]
  call output_buffer_push

  ; not pushing ; here so it can be done in loop
  ; since there is no ; after b and instead an m

  ; convert r, g and b to ascii and push

  mov byte [rbp - 2], -1

  .conversionloop:
    inc byte [rbp - 2]
    cmp byte [rbp - 2], 3
    jge .conversionend

    ; previous delimiter
    mov rdi, output_buffer
    mov byte [rbp - 1], ';'
    lea rsi, [rbp - 1]
    call output_buffer_push

    ; convert
    movzx rax, byte [r12]

    ; ascii offset = value * 3
    mov rdi, rax
    shl rdi, 1
    add rdi, rax

    mov sil, byte [uint8ASCII + rdi + 0]
    mov byte [rbp - 3], sil
    mov sil, byte [uint8ASCII + rdi + 1]
    mov byte [rbp - 4], sil
    mov sil, byte [uint8ASCII + rdi + 2]
    mov byte [rbp - 5], sil

    mov rdi, output_buffer
    lea rsi, [rbp - 3]
    call output_buffer_push
    mov rdi, output_buffer
    lea rsi, [rbp - 4]
    call output_buffer_push
    mov rdi, output_buffer
    lea rsi, [rbp - 5]
    call output_buffer_push

    inc r12
  jmp .conversionloop

  .conversionend:
  mov rdi, output_buffer
  mov byte [rbp - 1], 'm'
  lea rsi, [rbp - 1]
  call output_buffer_push

  .exit:
  mov rsp, rbp
  pop r12
  pop rbp
  ret


; arg1 rdi = &cell
generate_flags:
  push rbp
  mov  rbp, rsp

  mov rsp, rbp
  pop rbp
  ret


; arg1 rdi = &cell
generate_text:
  push rbp
  push r12
  mov  rbp, rsp

  sub rsp, 8
  mov r12, rdi

  ; load first byte into stack memory
  mov al, byte [r12 + cell.text]
  mov byte [rbp - 1], al

  ; init counter
  mov byte [rbp - 2], 0

  ; check if first bit is 0 (most common case)
  ; yes = push 1 byte and exit
  ; no  = number of bytes is equal to 1s in first byte before first 0
  test al, 0b10000000
  jnz .pushloop

  ; push text
  mov rdi, output_buffer
  lea rsi, [r12 + cell.text]
  call output_buffer_push
  jmp .exit

  ; NOTE: lzcnt instruction could have been used for counting trailing 0s
  ; (by using not for inverting 1s first)

  .pushloop:
    shl byte [rbp - 1], 1
    jnc .exit

    ; load counter
    movzx rcx, byte [rbp - 2]

    ; push text
    mov rdi, output_buffer
    lea rsi, [r12 + cell.text + rcx]
    call output_buffer_push

    inc byte [rbp - 2]
  jmp .pushloop

  ; TODO: handle 2 wide / 0 wide character

  .exit:

  ; not handling colum overflow so on next cell generation, generate_position()
  ; explicitly jumps to required row and col instead of relying on terminal line wrapping
  inc word [current_term_state + term_state.cursorx]

  mov rsp, rbp
  pop r12
  pop rbp
  ret

