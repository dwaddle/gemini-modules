; screen.asm - Viewport-based Screen Control with Colors and Borders
%include "algemeen.mac"
%include "syscalls.inc"
%include "screen.mac"
%include "screen_constants.inc"

section .data
    esc_clear       db 27, '[2J', 27, '[H', 0
    esc_reset       db 27, '[0m', 0
    esc_hide        db 27, '[?25l', 0
    esc_show        db 27, '[?25h', 0
    esc_fg_pre      db 27, '[3', 0
    esc_bg_pre      db 27, '[4', 0
    esc_scroll_pre  db 27, '[', 0
    
    ; Border characters (ASCII)
    b_tl db '+', 0
    b_tr db '+', 0
    b_bl db '+', 0
    b_br db '+', 0
    b_h  db '-', 0
    b_v  db '|', 0

section .text
    global _screen_clear, _screen_reset_color, _screen_set_bgcolor, _screen_hide_cursor, _screen_show_cursor
    global _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_set_color, _viewport_set_border
    
    extern PrintString, _int_to_str, _mem_alloc, _mem_set, _mem_copy, _cursor_goto_xy, _strlen

; --- [ Viewport Aanmaken ] ---
_viewport_create:
    @save_context
    mov r12, rdi ; X
    mov r13, rsi ; Y
    mov r14, rdx ; W
    mov r15, rcx ; H
    mov rbp, r8  ; BufH

    mov rdi, VP_SIZE
    call _mem_alloc
    push rax

    mov [rax + VP_X], r12
    mov [rax + VP_Y], r13
    mov [rax + VP_W], r14
    mov [rax + VP_H], r15
    mov [rax + VP_BUF_H], rbp
    mov qword [rax + VP_VIEW_Y], 0
    mov byte [rax + VP_FG], COL_WHITE
    mov byte [rax + VP_BG], COL_BLACK
    mov byte [rax + VP_FLAGS], VPF_NONE

    mov rax, rbp
    mul r14
    mov rdi, rax
    call _mem_alloc
    pop rbx
    mov [rbx + VP_BUF], rax
    
    mov rdi, rax
    mov rsi, ' '
    mov rax, [rbx + VP_BUF_H]
    mul qword [rbx + VP_W]
    mov rdx, rax
    call _mem_set

    mov rax, rbx
    @restore_context
    ret

; --- [ Viewport Kleur Instellen ] ---
; Input: RDI=VP, RSI=FG, RDX=BG
_viewport_set_color:
    mov [rdi + VP_FG], sil
    mov [rdi + VP_BG], dl
    ret

; --- [ Viewport Border Instellen ] ---
; Input: RDI=VP, RSI=Status (1/0)
_viewport_set_border:
    test rsi, rsi
    jz .disable
    or byte [rdi + VP_FLAGS], VPF_BORDER
    ret
.disable:
    and byte [rdi + VP_FLAGS], ~VPF_BORDER
    ret

; --- [ Schrijf naar Viewport ] ---
; Input: RDI=VP_Ptr, RSI=LocalX, RDX=LocalY, RCX=String_Ptr
_viewport_write:
    @save_context
    mov r12, rdi ; VP
    mov r13, rsi ; Current LX
    mov r14, rdx ; Current LY
    mov r15, rcx ; Current string pointer

.loop:
    ; Check for end of string
    cmp byte [r15], 0
    je .done

    ; Check if we exceeded buffer height
    cmp r14, [r12 + VP_BUF_H]
    jae .done

    ; Handle spaces (leading or within)
    cmp byte [r15], ' '
    jne .handle_word
    
    ; If we have space, check if it fits at end of line
    cmp r13, [r12 + VP_W]
    jb .write_space
    
    ; Exact end of line, wrap before space
    mov r13, 0
    inc r14
    cmp r14, [r12 + VP_BUF_H]
    jae .done

.write_space:
    mov rsi, r15
    mov rdx, 1
    call _write_segment
    inc r15
    jmp .check_bounds

.handle_word:
    ; Find next word and its length
    mov rdi, r15
    call _find_next_word
    test rax, rax
    jz .done
    
    mov rbx, rax        ; Pointer to word
    mov r10, rdx        ; Length of word
    
    ; Check if word fits on current line
    mov rax, r13
    add rax, r10
    cmp rax, [r12 + VP_W]
    jle .write_it       ; Fits!
    
    ; Does not fit. Word wrap: Move to next line (if not already at LX=0)
    test r13, r13
    jz .truncate_word   ; Already at start of line, but still doesn't fit! Truncate.
    
    mov r13, 0          ; LX = 0
    inc r14             ; LY++
    cmp r14, [r12 + VP_BUF_H]
    jae .done

    ; Try again on the new line
    mov rax, r13
    add rax, r10
    cmp rax, [r12 + VP_W]
    jle .write_it

.truncate_word:
    ; Word is too long for the whole viewport width. Truncate it to fit the line.
    mov r10, [r12 + VP_W]
    sub r10, r13        ; Remaining space on line

.write_it:
    ; Write the word segment
    mov rdi, r12
    mov rsi, rbx
    mov rdx, r10
    call _write_segment
    
    ; Move string pointer past the written part
    add r15, r10

.check_bounds:
    ; If we reached or exceeded end of line, wrap to next line
    cmp r13, [r12 + VP_W]
    jb .loop
    
    mov r13, 0
    inc r14
    jmp .loop

.done:
    @restore_context
    ret

; --- Helper Functions for _viewport_write ---

; Writes a segment of a string to the buffer at current X,Y
; Input: RDI=VP, RSI=String segment pointer, RDX=Length
; Modifies: R13 (increments LX)
_write_segment:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r10
    push r12

    mov r12, rdi        ; VP
    mov rbx, rsi        ; String segment pointer
    mov r10, rdx        ; Length

    ; Calculate buffer position: (LY * W) + LX
    mov rax, r14        ; Current LY
    mul qword [r12 + VP_W]
    add rax, r13        ; Current LX
    add rax, [r12 + VP_BUF]
    mov rdi, rax        ; Destination in buffer

    mov rsi, rbx        ; Source string
    mov rdx, r10        ; Length
    call _mem_copy      ; Copy segment to buffer

    ; Increment current X position (r13)
    add r13, r10
    
    pop r12
    pop r10
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Helper to find the next word and its length
; Input: RDI = String pointer
; Output: RAX = Pointer to start of word, RDX = Word length (or 0 if end of string/only spaces)
_find_next_word:
    push rsi
    push rdi
    push r8
    push r10

    mov rsi, rdi        ; String pointer
    mov r10, 0          ; Word length

    ; Skip leading spaces
.skip_spaces_find:
    cmp byte [rsi], ' '
    jne .word_start_find
    cmp byte [rsi], 0   ; End of string
    je .end_of_string_find
    inc rsi
    jmp .skip_spaces_find

.word_start_find:
    mov rdi, rsi        ; Save start of word
.count_word_len_find:
    movzx r8, byte [rsi + r10]
    cmp r8, 0           ; End of string?
    je .word_found
    cmp r8, ' '         ; Space found?
    je .word_found
    inc r10
    jmp .count_word_len_find

.word_found:
    mov rax, rdi        ; Pointer to start of word
    mov rdx, r10        ; Word length
    jmp .done_find

.end_of_string_find:
    xor rax, rax        ; Indicate no word found
    xor rdx, rdx

.done_find:
    pop r10
    pop r8
    pop rdi
    pop rsi
    ret

; --- [ Render Viewport ] ---
_viewport_render:
    @save_context
    mov r12, rdi ; VP
    call _screen_hide_cursor

    ; 1. Optioneel: Border Tekenen
    test byte [r12 + VP_FLAGS], VPF_BORDER
    jz .skip_border
    call _viewport_draw_border_internal
.skip_border:

    ; 2. Kleuren instellen
    call _viewport_apply_color_internal

    ; 3. Inhoud renderen
    mov r13, 0 ; Visible Line
.line_loop:
    mov rax, [r12 + VP_VIEW_Y]
    add rax, r13
    cmp rax, [r12 + VP_BUF_H]
    jae .done_rendering
    
    mul qword [r12 + VP_W]
    add rax, [r12 + VP_BUF]
    mov r14, rax

    ; Fysieke positie (houd rekening met border indien aanwezig)
    mov rdi, [r12 + VP_Y]
    add rdi, r13
    inc rdi
    mov rsi, [r12 + VP_X]
    inc rsi
    
    test byte [r12 + VP_FLAGS], VPF_BORDER
    jz .no_border_offset
    inc rdi
    inc rsi
.no_border_offset:
    call _cursor_goto_xy
    
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, r14
    mov rdx, [r12 + VP_W]
    syscall
    
    inc r13
    cmp r13, [r12 + VP_H]
    jb .line_loop

.done_rendering:
    call _screen_reset_color
    call _screen_show_cursor
    @restore_context
    ret

; --- [ Interne Helpers ] ---

_viewport_apply_color_internal:
    ; Voorgrond
    mov rdi, esc_fg_pre
    call PrintString
    movzx rax, byte [r12 + VP_FG]
    sub rsp, 16
    add al, '0'
    mov [rsp], al
    mov byte [rsp+1], 'm'
    mov byte [rsp+2], 0
    mov rdi, rsp
    call PrintString
    add rsp, 16
    
    ; Achtergrond
    mov rdi, esc_bg_pre
    call PrintString
    movzx rax, byte [r12 + VP_BG]
    sub rsp, 16
    add al, '0'
    mov [rsp], al
    mov byte [rsp+1], 'm'
    mov byte [rsp+2], 0
    mov rdi, rsp
    call PrintString
    add rsp, 16
    ret

_viewport_draw_border_internal:
    ; Teken een box rond de viewport (X, Y tot X+W+1, Y+H+1)
    mov r14, [r12 + VP_W]
    add r14, 1 ; Rechterkant
    mov r15, [r12 + VP_H]
    add r15, 1 ; Onderkant

    ; TL Corner
    mov rdi, [r12 + VP_Y]
    inc rdi
    mov rsi, [r12 + VP_X]
    inc rsi
    call _cursor_goto_xy
    mov rdi, b_tl
    call PrintString

    ; Top edge
    mov rcx, [r12 + VP_W]
.t_loop:
    mov rdi, b_h
    push rcx
    call PrintString
    pop rcx
    loop .t_loop

    ; TR Corner
    mov rdi, b_tr
    call PrintString

    ; Vertical lines
    mov rcx, [r12 + VP_H]
    mov r13, 1
.v_loop:
    push rcx
    mov rdi, [r12 + VP_Y]
    add rdi, r13
    inc rdi
    mov rsi, [r12 + VP_X]
    inc rsi
    call _cursor_goto_xy
    mov rdi, b_v
    call PrintString
    
    mov rsi, [r12 + VP_X]
    add rsi, [r12 + VP_W]
    add rsi, 2
    call _cursor_goto_xy
    mov rdi, b_v
    call PrintString
    
    inc r13
    pop rcx
    loop .v_loop

    ; Bottom line
    mov rdi, [r12 + VP_Y]
    add rdi, [r12 + VP_H]
    add rdi, 2
    mov rsi, [r12 + VP_X]
    inc rsi
    call _cursor_goto_xy
    mov rdi, b_bl
    call PrintString
    
    mov rcx, [r12 + VP_W]
.b_loop:
    mov rdi, b_h
    push rcx
    call PrintString
    pop rcx
    loop .b_loop
    
    mov rdi, b_br
    call PrintString
    ret

; --- [ Scroll Viewport ] ---
_viewport_scroll:
    @save_context
    mov r12, rdi
    mov rax, [r12 + VP_VIEW_Y]
    add rax, rsi
    test rax, rax
    js .set_zero
    mov rbx, [r12 + VP_BUF_H]
    sub rbx, [r12 + VP_H]
    cmp rax, rbx
    jle .update
    mov rax, rbx
    jmp .update
.set_zero:
    xor rax, rax
.update:
    mov [r12 + VP_VIEW_Y], rax
    mov rdi, r12
    call _viewport_render
    @restore_context
    ret

; --- [ Basis Functies ] ---
_screen_clear:
    mov rdi, esc_clear
    call PrintString
    ret

_screen_reset_color:
    mov rdi, esc_reset
    call PrintString
    ret

_screen_hide_cursor:
    mov rdi, esc_hide
    call PrintString
    ret

_screen_show_cursor:
    mov rdi, esc_show
    call PrintString
    ret

_screen_set_bgcolor:
    @save_context
    mov r12, rdi
    mov rdi, esc_bg_pre
    call PrintString
    sub rsp, 16
    add r12b, '0'
    mov [rsp], r12b
    mov byte [rsp+1], 'm'
    mov byte [rsp+2], 0
    mov rdi, rsp
    call PrintString
    add rsp, 16
    @restore_context
    ret
