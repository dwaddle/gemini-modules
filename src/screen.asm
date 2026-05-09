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

    ; --- Screen Engine Data ---
    screen_buffer   dq 0        ; Pointer naar SCR_SIZE bytes
    screen_initialized db 0

section .text
    global _screen_clear, _screen_reset_color, _screen_set_bgcolor, _screen_hide_cursor, _screen_show_cursor
    global _screen_init, _screen_flip
    global _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_set_color, _viewport_set_border, _viewport_set_title
    global _viewport_clear, _viewport_move, _viewport_write_aligned, _viewport_set_border_color, _viewport_set_focus
    
    extern PrintString, _int_to_str, _mem_alloc, _mem_set, _mem_copy, _cursor_goto_xy, _strlen

; --- [ Screen: Initialiseer Back Buffer ] ---
_screen_init:
    push rbx
    cmp byte [screen_initialized], 1
    je .done
    
    mov rdi, SCR_SIZE
    call _mem_alloc
    mov [screen_buffer], rax
    
    ; Clear buffer initially
    mov rdi, rax
    mov rsi, ' '
    mov rdx, SCR_SIZE
    call _mem_set
    
    mov byte [screen_initialized], 1
.done:
    pop rbx
    ret

; --- [ Screen: Flip (Commit Back Buffer naar Terminal) ] ---
_screen_flip:
    @save_callee_saved
    mov r12, [screen_buffer]
    test r12, r12
    jz .done
    
    call _screen_hide_cursor
    
    xor r13, r13        ; R13 = Huidige regel
.row_loop:
    mov rdi, r13
    inc rdi
    mov rsi, 1
    call _cursor_goto_xy
    
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, r12
    mov rdx, SCR_W
    syscall
    
    add r12, SCR_W
    inc r13
    cmp r13, SCR_H
    jl .row_loop
    
    call _screen_show_cursor
.done:
    @restore_callee_saved
    ret

; --- [ Viewport Aanmaken ] ---
_viewport_create:
    @save_callee_saved
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
_viewport_set_title:
    mov [rdi + VP_TITLE], rsi
    ret

; --- [ Viewport Border Kleur Instellen ] ---
_viewport_set_border_color:
    mov [rdi + VP_B_FG], sil
    mov [rdi + VP_B_BG], dl
    ret

; --- [ Viewport Focus Instellen ] ---
_viewport_set_focus:
    test rsi, rsi
    jz .blur
    or byte [rdi + VP_FLAGS], VPF_FOCUS
    ret
.blur:
    and byte [rdi + VP_FLAGS], ~VPF_FOCUS
    ret

; --- [ Schrijf naar Viewport met Uitlijning ] ---
_viewport_write_aligned:
    @save_callee_saved
    mov r12, rdi ; VP
    mov r13, rsi ; LY
    mov r14, rdx ; StrPtr
    mov r15, rcx ; Align

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

; --- [ Schrijf naar Viewport ] ---
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

; --- [ Render Viewport ] ---
_viewport_render:
    @save_callee_saved
    mov r12, rdi ; VP
    call _screen_init
    
    ; Note: Colors are currently not supported in the double-buffer char array.
    ; This would require a separate attribute buffer.
    
    test byte [r12 + VP_FLAGS], VPF_BORDER
    jz .skip_border
    call _viewport_draw_border_internal
.skip_border:

    mov r13, 0          ; R13 = Viewport line
.line_loop:
    mov rax, [r12 + VP_VIEW_Y]
    add rax, r13
    cmp rax, [r12 + VP_BUF_H]
    jae .done_rendering
    
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
    add rax, [screen_buffer]
    mov rdi, rax        ; Dest
    
    mov rsi, r14
    mov rdx, [r12 + VP_W]
    call _mem_copy

.next_line:
    inc r13
    cmp r13, [r12 + VP_H]
    jb .line_loop

.done_rendering:
    @restore_callee_saved
    ret

_viewport_draw_border_internal:
    ; Simpele implementatie die direct naar de screen_buffer schrijft
    @save_callee_saved
    
    ; Top row
    mov rax, [r12 + VP_Y]
    imul rax, SCR_W
    add rax, [r12 + VP_X]
    add rax, [screen_buffer]
    mov rdi, rax
    mov byte [rdi], '+'
    inc rdi
    mov rcx, [r12 + VP_W]
    mov al, '-'
    rep stosb
    mov byte [rdi], '+'
    
    ; Bottom row
    mov rax, [r12 + VP_Y]
    add rax, [r12 + VP_H]
    inc rax
    imul rax, SCR_W
    add rax, [r12 + VP_X]
    add rax, [screen_buffer]
    mov rdi, rax
    mov byte [rdi], '+'
    inc rdi
    mov rcx, [r12 + VP_W]
    mov al, '-'
    rep stosb
    mov byte [rdi], '+'
    
    ; Sides
    mov rcx, [r12 + VP_H]
    mov r13, 1
.v_loop:
    mov rax, [r12 + VP_Y]
    add rax, r13
    imul rax, SCR_W
    add rax, [r12 + VP_X]
    add rax, [screen_buffer]
    mov byte [rax], '|'
    add rax, [r12 + VP_W]
    inc rax
    mov byte [rax], '|'
    inc r13
    loop .v_loop

    @restore_callee_saved
    ret

; --- [ Scroll Viewport ] ---
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

; --- [ Viewport Leegmaken ] ---
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

; --- [ Viewport Verplaatsen ] ---
_viewport_move:
    mov [rdi + VP_X], rsi
    mov [rdi + VP_Y], rdx
    ret
