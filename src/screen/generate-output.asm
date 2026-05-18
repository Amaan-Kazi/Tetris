; screen/state
extern screen
extern output_buffer
extern debug_mode
extern current_term_state

; terminal/size
extern term.ws_col


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
      ; call generate_cell

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

