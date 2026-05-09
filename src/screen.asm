; screen.asm - Professional Viewport Engine with Double Buffering and Attributes
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
    
    b_tl db '+', 0
    b_tr db '+', 0
    b_bl db '+', 0
    b_br db '+', 0
    b_h  db '-', 0
    b_v  db '|', 0
    
    t_pre  db ' [', 0
    t_post db '] ', 0

    screen_buffer       dq 0        
    screen_initialized  db 0

section .text
    global _screen_clear, _screen_reset_color, _screen_set_bgcolor, _screen_hide_cursor, _screen_show_cursor
    global _screen_init, _screen_flip
    global _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_set_color, _viewport_set_border, _viewport_set_title
    global _viewport_clear, _viewport_move, _viewport_write_aligned, _viewport_set_border_color, _viewport_set_focus
    
    extern PrintString, _int_to_str, _mem_alloc, _mem_set, _mem_copy, _cursor_goto_xy, _strlen

; --- [ Screen: Initialize ] ---
_screen_init:
    push rbx
    cmp byte [screen_initialized], 1
    je .done
    
    mov rdi, SCR_SIZE * 2
    call _mem_alloc
    mov [screen_buffer], rax
    
    mov rdi, rax
    mov rcx, SCR_SIZE
    mov ax, 0x0720      ; White on Black, Space
    rep stosw
    
    mov byte [screen_initialized], 1
.done:
    pop rbx
    ret

; --- [ Screen: Flip ] ---
_screen_flip:
    @save_callee_saved
    mov r12, [screen_buffer]
    test r12, r12
    jz .done
    
    call _screen_hide_cursor
    
    xor r13, r13        ; Y
    mov r15, 0xFFFF     ; Current Attr (invalid)

.row_loop:
    mov rdi, r13
    inc rdi
    mov rsi, 1
    call _cursor_goto_xy
    
    xor r14, r14        ; X
.cell_loop:
    movzx rax, word [r12]
    mov rbx, rax
    shr rbx, 8          ; RBX = Attr
    
    cmp bl, r15b
    je .write_char
    
    mov r15b, bl
    call _apply_attr_internal
    
.write_char:
    movzx rdi, al
    push rax
    sub rsp, 8
    mov [rsp], dil
    mov byte [rsp+1], 0
    mov rdi, rsp
    call PrintString
    add rsp, 8
    pop rax
    
    add r12, 2
    inc r14
    cmp r14, SCR_W
    jl .cell_loop

    inc r13
    cmp r13, SCR_H
    jl .row_loop
    
    call _screen_reset_color
    call _screen_show_cursor
.done:
    @restore_callee_saved
    ret

_apply_attr_internal:
    push r12
    mov r12b, r15b
    
    mov rdi, esc_fg_pre
    call PrintString
    movzx rax, r12b
    and rax, 0x0F
    add al, '0'
    sub rsp, 16
    mov [rsp], al
    mov byte [rsp+1], 'm'
    mov byte [rsp+2], 0
    mov rdi, rsp
    call PrintString
    add rsp, 16
    
    mov rdi, esc_bg_pre
    call PrintString
    movzx rax, r12b
    shr rax, 4
    and rax, 0x0F
    add al, '0'
    sub rsp, 16
    mov [rsp], al
    mov byte [rsp+1], 'm'
    mov byte [rsp+2], 0
    mov rdi, rsp
    call PrintString
    add rsp, 16
    
    pop r12
    ret

; --- [ Viewport: Create ] ---
_viewport_create:
    @save_callee_saved
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbp, r8

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
    mov byte [rax + VP_B_FG], COL_WHITE
    mov byte [rax + VP_B_BG], COL_BLACK
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
    @restore_callee_saved
    ret

; --- [ Viewport: Render ] ---
_viewport_render:
    @save_callee_saved
    mov r12, rdi
    call _screen_init
    
    test byte [r12 + VP_FLAGS], VPF_BORDER
    jz .skip_border
    call _viewport_draw_border_internal
.skip_border:

    movzx rbx, byte [r12 + VP_BG]
    shl rbx, 4
    or bl, [r12 + VP_FG] 
    mov r15, rbx       ; R15 = attribute in bl

    mov r13, 0
.line_loop:
    mov rax, [r12 + VP_VIEW_Y]
    add rax, r13
    cmp rax, [r12 + VP_BUF_H]
    jae .done
    
    mul qword [r12 + VP_W]
    add rax, [r12 + VP_BUF]
    mov r14, rax        ; Source
    
    mov rax, [r12 + VP_Y]
    add rax, r13
    test byte [r12 + VP_FLAGS], VPF_BORDER
    jz .no_off_y
    inc rax
.no_off_y:
    cmp rax, SCR_H
    jae .next_line
    
    imul rax, SCR_W
    add rax, [r12 + VP_X]
    test byte [r12 + VP_FLAGS], VPF_BORDER
    jz .no_off_x
    inc rax
.no_off_x:
    lea rdi, [rax * 2]
    add rdi, [screen_buffer]
    
    mov rcx, [r12 + VP_W]
.copy_cell_loop:
    movzx rax, byte [r14] ; Char
    mov rbx, r15
    shl rbx, 8          ; Attr in bits 8-15
    or rax, rbx         ; Combined cell
    mov [rdi], ax
    add rdi, 2
    inc r14
    loop .copy_cell_loop

.next_line:
    inc r13
    cmp r13, [r12 + VP_H]
    jb .line_loop

.done:
    @restore_callee_saved
    ret

_viewport_draw_border_internal:
    @save_callee_saved
    movzx rbx, byte [r12 + VP_B_BG]
    shl rbx, 4
    or bl, [r12 + VP_B_FG]
    mov r15, rbx        ; Attr in r15b

    ; Top row
    mov rax, [r12 + VP_Y]
    imul rax, SCR_W
    add rax, [r12 + VP_X]
    lea rdi, [rax * 2]
    add rdi, [screen_buffer]
    
    mov rax, '+'
    mov rbx, r15
    shl rbx, 8
    or rax, rbx
    stosw
    
    mov rcx, [r12 + VP_W]
    mov rax, '-'
    or rax, rbx
    rep stosw
    
    mov rax, '+'
    or rax, rbx
    stosw
    
    ; Bottom row
    mov rax, [r12 + VP_Y]
    add rax, [r12 + VP_H]
    inc rax
    imul rax, SCR_W
    add rax, [r12 + VP_X]
    lea rdi, [rax * 2]
    add rdi, [screen_buffer]
    
    mov rax, '+'
    or rax, rbx
    stosw
    mov rcx, [r12 + VP_W]
    mov rax, '-'
    or rax, rbx
    rep stosw
    mov rax, '+'
    or rax, rbx
    stosw
    
    ; Sides
    mov rcx, [r12 + VP_H]
    mov r13, 1
.v_loop:
    mov rax, [r12 + VP_Y]
    add rax, r13
    imul rax, SCR_W
    add rax, [r12 + VP_X]
    lea rdi, [rax * 2]
    add rdi, [screen_buffer]
    
    mov rax, '|'
    mov rbx, r15
    shl rbx, 8
    or rax, rbx
    mov [rdi], ax
    
    mov rax, [r12 + VP_W]
    inc rax
    lea rdi, [rdi + rax * 2]
    mov rax, '|'
    or rax, rbx
    mov [rdi], ax
    
    inc r13
    loop .v_loop

    @restore_callee_saved
    ret

_viewport_scroll:
    @save_callee_saved
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
    @restore_callee_saved
    ret

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
    @save_callee_saved
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
    @restore_callee_saved
    ret

_viewport_clear:
    @save_callee_saved
    mov r12, rdi
    mov rdi, [r12 + VP_BUF]
    mov rsi, ' '
    mov rax, [r12 + VP_BUF_H]
    mul qword [r12 + VP_W]
    mov rdx, rax
    call _mem_set
    mov qword [r12 + VP_VIEW_Y], 0
    @restore_callee_saved
    ret

_viewport_move:
    mov [rdi + VP_X], rsi
    mov [rdi + VP_Y], rdx
    ret

_viewport_set_color:
    mov [rdi + VP_FG], sil
    mov [rdi + VP_BG], dl
    ret

_viewport_set_border:
    test rsi, rsi
    jz .disable
    or byte [rdi + VP_FLAGS], VPF_BORDER
    ret
.disable:
    and byte [rdi + VP_FLAGS], ~VPF_BORDER
    ret

_viewport_set_title:
    mov [rdi + VP_TITLE], rsi
    ret

_viewport_set_border_color:
    mov [rdi + VP_B_FG], sil
    mov [rdi + VP_B_BG], dl
    ret

_viewport_set_focus:
    test rsi, rsi
    jz .blur
    or byte [rdi + VP_FLAGS], VPF_FOCUS
    ret
.blur:
    and byte [rdi + VP_FLAGS], ~VPF_FOCUS
    ret

_viewport_write_aligned:
    @save_callee_saved
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rdi, r14
    call _strlen
    mov rbx, rax
    xor rsi, rsi
    cmp r15, ALIGN_CENTER
    je .center
    cmp r15, ALIGN_RIGHT
    je .right
    jmp .do_write
.center:
    mov rax, [r12 + VP_W]
    sub rax, rbx
    js .set_zero
    shr rax, 1
    mov rsi, rax
    jmp .do_write
.right:
    mov rax, [r12 + VP_W]
    sub rax, rbx
    js .set_zero
    mov rsi, rax
    jmp .do_write
.set_zero:
    xor rsi, rsi
.do_write:
    mov rdi, r12
    mov rdx, r13
    mov rcx, r14
    call _viewport_write
    @restore_callee_saved
    ret

_viewport_write:
    @save_callee_saved
    mov r12, rdi ; VP
    mov r13, rsi ; Current LX
    mov r14, rdx ; Current LY
    mov r15, rcx ; Current string pointer
.loop:
    movzx rax, byte [r15]
    test al, al
    jz .check_autoscroll
    cmp r14, [r12 + VP_BUF_H]
    jae .check_autoscroll
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
.check_autoscroll:
    test byte [r12 + VP_FLAGS], VPF_AUTOSCROLL
    jz .done
    mov rax, [r12 + VP_VIEW_Y]
    add rax, [r12 + VP_H]
    dec rax
    cmp r14, rax
    jle .done
    mov rax, r14
    sub rax, [r12 + VP_H]
    inc rax
    test rax, rax
    jns .set_scroll
    xor rax, rax
.set_scroll:
    mov [r12 + VP_VIEW_Y], rax
.done:
    @restore_callee_saved
    ret

_write_segment:
    @save_callee_saved
    ; RDI=VP, RSI=Str, RDX=Len, R14=LY, R13=LX
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
    
    @restore_callee_saved
    ret
