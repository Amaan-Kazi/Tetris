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

  ; TODO: update current_term_state if position changed

  .exit:
  mov rsp, rbp
  multipop r13, r12
  pop rbp
  ret


; arg1 rdi = &cell
generate_color:
  push rbp
  mov  rbp, rsp

  mov rsp, rbp
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
  mov  rbp, rsp

  sub rsp, 8

  ; load text into stack memory
  mov al, byte [rdi + cell.text]
  mov byte [rbp - 1], al

  ; push text
  mov rdi, output_buffer
  lea rsi, [rbp - 1]
  call output_buffer_push

  ; TODO: handle 2 wide / 0 wide character
  inc word [current_term_state + term_state.cursorx]

  mov rsp, rbp
  pop rbp
  ret

