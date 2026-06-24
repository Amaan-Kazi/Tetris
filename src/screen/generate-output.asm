default rel

; screen/state
extern screen
extern output_buffer
extern output_buffer_push
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

%include "src/util/cell-flags.mac"

DEFINE_VECTOR rect_vec, rect_size


section .bss
rect_vec resb vector_size
sgr_started resb 1


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
  multipush r12, r13, r14
  mov  rbp, rsp

  sub rsp, 8

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

  ; if cell.width is 0 then skip cell
  cmp byte [rdi + cell.width], CELL_WIDTH_0
  je .exit

  mov rdi, r12
  mov rsi, r13
  call generate_position

  mov byte [sgr_started], 0

  mov rdi, r14
  mov rsi, 0   ; background
  call generate_color

  mov rdi, r14
  mov rsi, 1   ; foreground
  call generate_color

  mov rdi, r14
  mov rsi, 2   ; underline
  call generate_color

  mov rdi, r14
  call generate_flags

  ; if sgr_started, then we must end it with m
  cmp byte [sgr_started], 0
  je .generate_text
    ; if ; at end then remove it
    mov rax, qword [output_buffer + vector.data]
    mov rdx, qword [output_buffer + vector.size]
    mov dil, byte  [rax + rdx - 1]

    cmp dil, ';'
    jne .no_semicolon
      mov byte [rax + rdx - 1], 'm'
      jmp .generate_text

    .no_semicolon:
    lea rdi, [output_buffer]
    mov byte [rbp - 1], 'm'
    lea rsi, [rbp - 1]
    call output_buffer_push

  .generate_text:
  mov rdi, r14
  call generate_text

  .exit:
  mov rsp, rbp
  multipop r14, r13, r12
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
  movzx rdi, word [current_term_state + term_state.cursory]
  cmp   rdi, rsi
  je   .row_equal

  lea rdi, [output_buffer]
  mov byte [rbp - 48], 0x1b ; ESC
  lea rsi, [rbp - 48]
  call output_buffer_push

  lea rdi, [output_buffer]
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
    lea rdi, [output_buffer]
    lea rsi, [rbp - 36 + r12]
    call output_buffer_push

    inc r12
    cmp r12, r13
  jl .ycopyloop

  lea rdi, [output_buffer]
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
    lea rdi, [output_buffer]
    lea rsi, [rbp - 36 + r12]
    call output_buffer_push

    inc r12
    cmp r12, r13
  jl .xcopyloop

  lea rdi, [output_buffer]
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
  lea   rdi, [current_term_state]
  movzx rdi, word [rdi + term_state.cursorx]
  cmp   rdi, qword [rbp - 8]
  je   .exit

  lea rdi, [output_buffer]
  mov byte [rbp - 48], 0x1b ; ESC
  lea rsi, [rbp - 48]
  call output_buffer_push

  lea rdi, [output_buffer]
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
    lea rdi, [output_buffer]
    lea rsi, [rbp - 36 + r12]
    call output_buffer_push

    inc r12
    cmp r12, r13
  jl .xcopyloop2

  lea rdi, [output_buffer]
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
; arg2 rsi = color, 0 = background, 1 = foreground, 2 = underline
generate_color:
  push rbp
  push r12
  mov  rbp, rsp

  sub rsp, 8

  .background:
    cmp sil, 0
    jne .foreground

    lea r12, [rdi + cell.background]
    mov rax, term_state.background
    mov byte [rbp - 2], '4'
  jmp .color_selected

  .foreground:
    cmp sil, 1
    jne .underline

    lea r12, [rdi + cell.foreground]
    mov rax, term_state.foreground
    mov byte [rbp - 2], '3'
  jmp .color_selected

  .underline:
    cmp sil, 2
    jne .exit

    ; if cell has no underline then we can skip color
    cmp byte [rdi + cell.underline_type], 0
    je .exit

    lea r12, [rdi + cell.underline]
    mov rax, term_state.underline
    mov byte [rbp - 2], '5'
  jmp .color_selected

  .color_selected:

  mov rcx, -1 ; counter
  mov rdx, 0  ; track if current_term_state was changed
  lea r8, [current_term_state]

  .cmploop:
    inc rcx
    cmp rcx, 3
    jge .endcmploop

    ; compute address of current_term_state.color_type.value in r9
    mov r9, r8
    add r9, rax ; foreground / background / underline
    add r9, rcx ; r / g / b

    ; compare current_term_state with cell
    mov sil, byte [r12 + rcx]
    cmp sil, byte [r9]
    je .cmploop

    ; update current_term_state
    mov byte [r9], sil
    mov rdx, 1
  jmp .cmploop

  .endcmploop:

  ; if current_term_state not changed then we can exit
  cmp rdx, 0
  je .exit

  ; start sgr if not done already
  cmp byte [sgr_started], 1
  je .sgr_started
    lea rdi, [output_buffer]
    mov byte [rbp - 1], 0x1b ; ESC
    lea rsi, [rbp - 1]
    call output_buffer_push

    lea rdi, [output_buffer]
    mov byte [rbp - 1], '['
    lea rsi, [rbp - 1]
    call output_buffer_push

    mov byte [sgr_started], 1
  .sgr_started:

  ; ansi escape sequence for changing color

  lea rdi, [output_buffer]
  lea rsi, [rbp - 2]
  call output_buffer_push

  lea rdi, [output_buffer]
  mov byte [rbp - 1], '8'
  lea rsi, [rbp - 1]
  call output_buffer_push

  lea rdi, [output_buffer]
  mov byte [rbp - 1], ';'
  lea rsi, [rbp - 1]
  call output_buffer_push

  lea rdi, [output_buffer]
  mov byte [rbp - 1], '2'
  lea rsi, [rbp - 1]
  call output_buffer_push

  lea rdi, [output_buffer]
  mov byte [rbp - 1], ';'
  lea rsi, [rbp - 1]
  call output_buffer_push

  ; convert r, g and b to ascii and push

  mov byte [rbp - 2], -1 ; counter
  lea r9, [uint8ASCII]

  .conversionloop:
    inc byte [rbp - 2]
    cmp byte [rbp - 2], 3
    jge .exit

    ; convert
    movzx rax, byte [r12]

    ; ascii offset = value * 3
    mov rdi, rax
    shl rdi, 1
    add rdi, rax

    mov sil, byte [r9 + rdi + 0]
    mov byte [rbp - 3], sil
    mov sil, byte [r9 + rdi + 1]
    mov byte [rbp - 4], sil
    mov sil, byte [r9 + rdi + 2]
    mov byte [rbp - 5], sil

    ; skip starting 0s

    cmp byte [r12], 100
    jb .2digit
      lea rdi, [output_buffer]
      lea rsi, [rbp - 3]
      call output_buffer_push

    .2digit:
    cmp byte [r12], 10
    jb .1digit
      lea rdi, [output_buffer]
      lea rsi, [rbp - 4]
      call output_buffer_push

    .1digit:
      lea rdi, [output_buffer]
      lea rsi, [rbp - 5]
      call output_buffer_push

    ; delimiter
    lea rdi, [output_buffer]
    mov byte [rbp - 1], ';'
    lea rsi, [rbp - 1]
    call output_buffer_push

    inc r12
  jmp .conversionloop

  .exit:
  mov rsp, rbp
  pop r12
  pop rbp
  ret


; arg1 rdi = &cell
generate_flags:
  push rbp
  push r12
  mov  rbp, rsp

  sub rsp, 8

  mov r12b, byte [rdi + cell.flags]
  mov sil, byte [current_term_state + term_state.flags]
  mov byte [rbp - 1], sil

  mov dil, byte [rdi + cell.underline_type]
  mov byte [rbp - 2], dil

  ; any flag that is changed (enabled or disabled) will be set to 1
  xor sil, r12b
  mov byte [rbp - 3], sil

  mov dil, byte [current_term_state + term_state.underline_type]
  cmp dil, byte [rbp - 2]
  jne .changed

  ; if nothing has changed, then exit
  cmp sil, 0
  je .exit

  .changed:

  cmp byte [sgr_started], 1
  je .sgr_started
    ; start SGR
    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], 0x1b ; ESC
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '['
    lea  rsi, [rbp - 8]
    call output_buffer_push
  mov byte [sgr_started], 1

  .sgr_started:

  mov al, CELL_BOLD | CELL_DIM
  and al, r12b

  mov cl, CELL_BOLD | CELL_DIM
  and cl, byte [current_term_state + term_state.flags]

  cmp al, cl
  je .italic

  ; reset intensity, if already done then no need to repeat
  test byte [current_term_state + term_state.flags], CELL_BOLD | CELL_DIM
  jz .bold

  lea  rdi, [output_buffer]
  mov  byte [rbp - 8], '2'
  lea  rsi, [rbp - 8]
  call output_buffer_push

  lea  rdi, [output_buffer]
  mov  byte [rbp - 8], '2'
  lea  rsi, [rbp - 8]
  call output_buffer_push

  lea  rdi, [output_buffer]
  mov  byte [rbp - 8], ';'
  lea  rsi, [rbp - 8]
  call output_buffer_push

  .bold:
    test r12b, CELL_BOLD
    jz .dim

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '1'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push

  .dim:
    test r12b, CELL_DIM
    jz .italic

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '2'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push

  .italic:
    test byte [rbp - 3], CELL_ITALIC
    jz .blink

    test r12b, CELL_ITALIC
    jnz .italic_code

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '2'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    .italic_code:

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '3'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push

  .blink:
    test byte [rbp - 3], CELL_BLINK
    jz .inverse

    test r12b, CELL_BLINK
    jnz .blink_code

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '2'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    .blink_code:

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '5'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push

  .inverse:
    test byte [rbp - 3], CELL_INVERSE
    jz .hidden

    test r12b, CELL_INVERSE
    jnz .inverse_code

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '2'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    .inverse_code:

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '7'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push

  .hidden:
    test byte [rbp - 3], CELL_HIDDEN
    jz .strikethrough

    test r12b, CELL_HIDDEN
    jnz .hidden_code

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '2'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    .hidden_code:

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '8'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push

  .strikethrough:
    test byte [rbp - 3], CELL_STRIKETHROUGH
    jz .underline_type

    test r12b, CELL_STRIKETHROUGH
    jnz .strikethrough_code

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '2'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    .strikethrough_code:

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '9'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push

  .underline_type:
  mov dil, byte [rbp - 2]
  cmp dil, byte [current_term_state + term_state.underline_type]
  je .underline_handled

  cmp byte [rbp - 2], CELL_NO_UNDERLINE
  jne .single_underline
    ; No Underline
    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '2'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '4'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push
  jmp .underline_handled

  .single_underline:
  cmp byte [rbp - 2], CELL_SINGLE_UNDERLINE
  jne .double_underline
    ; Single Underline
    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '4'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push
  jmp .underline_handled

  .double_underline:
  cmp byte [rbp - 2], CELL_DOUBLE_UNDERLINE
  jne .other_underline
    ; Double Underline
    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '2'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '1'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push
  jmp .underline_handled

  .other_underline:
  cmp byte [rbp - 2], CELL_DASHED_UNDERLINE
  ja .underline_handled ; invalid
    ; Underlines are 4:3, 4:4 and 4:5
    ; for curly, dotted and dashed respectivetly
    ; 4:0, 4:1 and 4:2 are also available on new terminals
    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], '4'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ':'
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  sil, '0'
    add  sil, byte [rbp - 2]
    mov  byte [rbp - 8], sil
    lea  rsi, [rbp - 8]
    call output_buffer_push

    lea  rdi, [output_buffer]
    mov  byte [rbp - 8], ';'
    lea  rsi, [rbp - 8]
    call output_buffer_push

  .underline_handled:

  ; update current_term_state
  mov byte [current_term_state + term_state.flags], r12b
  mov dil, byte [rbp - 2]
  mov byte [current_term_state + term_state.underline_type], dil

  .exit:
  mov rsp, rbp
  pop r12
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
  lea rdi, [output_buffer]
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
    lea rdi, [output_buffer]
    lea rsi, [r12 + cell.text + rcx]
    call output_buffer_push

    inc byte [rbp - 2]
  jmp .pushloop

  .exit:

  ; handle character width
  ; normal  cell becomes 1
  ; wide    cell becomes 2
  ; 0 space cell shouldnt reach this function
  movzx di, byte [r12 + cell.width]
  inc di

  ; not handling colum overflow so on next cell generation, generate_position()
  ; explicitly jumps to required row and col instead of relying on terminal line wrapping
  add word [current_term_state + term_state.cursorx], di

  mov rsp, rbp
  pop r12
  pop rbp
  ret

