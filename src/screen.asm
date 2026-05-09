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
    
    t_pre  db ' [', 0
    t_post db '] ', 0

section .text
    global _screen_clear, _screen_reset_color, _screen_set_bgcolor, _screen_hide_cursor, _screen_show_cursor
    global _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_set_color, _viewport_set_border, _viewport_set_title
    
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
    mov qword [rax + VP_TITLE], 0

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
_viewport_set_color:
    mov [rdi + VP_FG], sil
    mov [rdi + VP_BG], dl
    ret

; --- [ Viewport Border Instellen ] ---
_viewport_set_border:
    test rsi, rsi
    jz .disable
    or byte [rdi + VP_FLAGS], VPF_BORDER
    ret
.disable:
    and byte [rdi + VP_FLAGS], ~VPF_BORDER
    ret

; --- [ Viewport Titel Instellen ] ---
; Input: RDI=VP, RSI=Titel String Pointer
_viewport_set_title:
    mov [rdi + VP_TITLE], rsi
    ret

; --- [ Schrijf naar Viewport ] ---
_viewport_write:
    @save_context
    mov r12, rdi ; VP
    mov r13, rsi ; Current LX
    mov r14, rdx ; Current LY
    mov r15, rcx ; Current string pointer

.loop:
    movzx rax, byte [r15]
    test al, al
    jz .done
    cmp r14, [r12 + VP_BUF_H]
    jae .done
    
    ; Geen word wrapping voor nu, gewoon letter per letter voor stabiliteit
    mov rdi, r12
    mov rsi, r15
    mov rdx, 1
    call _write_segment
    
    inc r15
    inc r13
    cmp r13, [r12 + VP_W]
    jb .loop
    
    mov r13, 0
    inc r14
    jmp .loop

.done:
    @restore_context
    ret

_write_segment:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r10
    push r12
    
    mov r12, rdi
    mov rbx, rsi
    mov r10, rdx
    
    ; Buffer offset = (LY * W) + LX
    mov rax, r14
    mul qword [r12 + VP_W]
    add rax, r13
    add rax, [r12 + VP_BUF]
    
    mov rdi, rax
    mov rsi, rbx
    mov rdx, r10
    call _mem_copy
    
    pop r12
    pop r10
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

_find_next_word:
    push rsi
    push rdi
    push r8
    push r10
    mov rsi, rdi
    mov r10, 0
.skip_spaces_find:
    cmp byte [rsi], ' '
    jne .word_start_find
    cmp byte [rsi], 0
    je .end_of_string_find
    inc rsi
    jmp .skip_spaces_find
.word_start_find:
    mov rdi, rsi
.count_word_len_find:
    movzx r8, byte [rsi + r10]
    cmp r8, 0
    je .word_found
    cmp r8, ' '
    je .word_found
    inc r10
    jmp .count_word_len_find
.word_found:
    mov rax, rdi
    mov rdx, r10
    jmp .done_find
.end_of_string_find:
    xor rax, rax
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
    test byte [r12 + VP_FLAGS], VPF_BORDER
    jz .skip_border
    push r13
    call _viewport_draw_border_internal
    pop r13
.skip_border:
    push r12
    call _viewport_apply_color_internal
    pop r12
    mov r13, 0
.line_loop:
    mov rax, [r12 + VP_VIEW_Y]
    add rax, r13
    cmp rax, [r12 + VP_BUF_H]
    jae .done_rendering
    mul qword [r12 + VP_W]
    add rax, [r12 + VP_BUF]
    mov r14, rax
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

_viewport_apply_color_internal:
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
    @save_context
    mov r14, [r12 + VP_W]
    add r14, 1
    mov r15, [r12 + VP_H]
    add r15, 1
    mov rdi, [r12 + VP_Y]
    inc rdi
    mov rsi, [r12 + VP_X]
    inc rsi
    call _cursor_goto_xy
    mov rdi, b_tl
    call PrintString
    
    ; Top edge with optional Title
    mov rbx, [r12 + VP_TITLE]
    test rbx, rbx
    jnz .draw_with_title
    
    mov rcx, [r12 + VP_W]
.t_loop:
    mov rdi, b_h
    push rcx
    call PrintString
    pop rcx
    loop .t_loop
    jmp .draw_corners

.draw_with_title:
    ; Bereken title lengte
    mov rdi, rbx
    call _strlen
    mov r13, rax ; Titel lengte
    
    ; Hoeveel streepjes links? (W - title_len - 4) / 2
    mov rax, [r12 + VP_W]
    sub rax, r13
    sub rax, 4 ; Ruimte voor " [] "
    js .no_space_for_title
    shr rax, 1 ; / 2
    mov rcx, rax
    push rax
.tl_loop:
    mov rdi, b_h
    push rcx
    call PrintString
    pop rcx
    loop .tl_loop
    
    mov rdi, t_pre
    call PrintString
    mov rdi, rbx ; De titel zelf
    call PrintString
    mov rdi, t_post
    call PrintString
    
    ; Streepjes rechts opvullen
    pop rax
    mov rcx, [r12 + VP_W]
    sub rcx, rax
    sub rcx, r13
    sub rcx, 4
.tr_loop:
    cmp rcx, 0
    jle .draw_corners
    mov rdi, b_h
    push rcx
    call PrintString
    pop rcx
    loop .tr_loop
    jmp .draw_corners

.no_space_for_title:
    ; Geen ruimte, teken gewoon streepjes
    mov rcx, [r12 + VP_W]
.ts_loop:
    mov rdi, b_h
    push rcx
    call PrintString
    pop rcx
    loop .ts_loop

.draw_corners:
    mov rdi, b_tr
    call PrintString
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
    mov rdi, [r12 + VP_Y]
    add rdi, r13
    inc rdi
    mov rsi, [r12 + VP_X]
    add rsi, [r12 + VP_W]
    add rsi, 2
    call _cursor_goto_xy
    mov rdi, b_v
    call PrintString
    inc r13
    pop rcx
    loop .v_loop
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
    @restore_context
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
