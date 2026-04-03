; screen.asm - Viewport-based Screen Control (x86_64 Linux)
%include "algemeen.mac"
%include "syscalls.inc"
%include "screen.mac"

section .data
    esc_clear       db 27, '[2J', 27, '[H', 0
    esc_reset       db 27, '[0m', 0
    esc_hide        db 27, '[?25l', 0
    esc_show        db 27, '[?25h', 0
    esc_bg_pre      db 27, '[4', 0
    esc_scroll_pre  db 27, '[', 0

section .text
    global _screen_clear, _screen_reset_color, _screen_set_bgcolor, _screen_hide_cursor, _screen_show_cursor
    global _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_clear
    
    extern PrintString, _int_to_str, _mem_alloc, _mem_set, _mem_copy, _cursor_goto_xy, _strlen

; --- [ Viewport Aanmaken ] ---
; Input: RDI=X, RSI=Y, RDX=W, RCX=H, R8=BufH
; Output: RAX = Pointer naar Viewport Struct
_viewport_create:
    @save_context
    mov r12, rdi ; X
    mov r13, rsi ; Y
    mov r14, rdx ; W
    mov r15, rcx ; H
    mov rbp, r8  ; BufH

    ; 1. Alloceren van de structuur (56 bytes)
    mov rdi, VP_SIZE
    call _mem_alloc
    push rax     ; Bewaar struct pointer

    ; 2. Vul de structuur
    mov [rax + VP_X], r12
    mov [rax + VP_Y], r13
    mov [rax + VP_W], r14
    mov [rax + VP_H], r15
    mov [rax + VP_BUF_H], rbp
    mov qword [rax + VP_VIEW_Y], 0

    ; 3. Alloceren van de tekstbuffer (BufH * W)
    mov rax, rbp
    mul r14
    mov rdi, rax
    call _mem_alloc
    
    pop rbx      ; Haal struct pointer terug
    mov [rbx + VP_BUF], rax
    
    ; 4. Buffer leegmaken (spaties)
    mov rdi, rax
    mov rsi, ' '
    mov rax, [rbx + VP_BUF_H]
    mul qword [rbx + VP_W]
    mov rdx, rax
    call _mem_set

    mov rax, rbx ; Return struct pointer
    @restore_context
    ret

; --- [ Schrijf naar Viewport ] ---
; Input: RDI=VP_Ptr, RSI=LocalX, RDX=LocalY, RCX=String_Ptr
_viewport_write:
    @save_context
    mov r12, rdi ; VP
    mov r13, rsi ; LX
    mov r14, rdx ; LY
    mov r15, rcx ; Str

    ; 1. Bereken lengte en check bounds
    mov rdi, r15
    call _strlen
    mov rbx, rax ; Lengte

    ; Truncatie check breedte
    mov rax, r13
    add rax, rbx
    cmp rax, [r12 + VP_W]
    jle .do_copy
    mov rax, [r12 + VP_W]
    sub rax, r13
    mov rbx, rax
.do_copy:
    ; 2. Bereken offset in buffer: (LY * W) + LX
    mov rax, r14
    mul qword [r12 + VP_W]
    add rax, r13
    add rax, [r12 + VP_BUF]
    
    mov rdi, rax ; Dest
    mov rsi, r15 ; Src
    mov rdx, rbx ; Count
    call _mem_copy
    @restore_context
    ret

; --- [ Render Viewport ] ---
; Input: RDI = VP_Ptr
_viewport_render:
    @save_context
    mov r12, rdi ; VP
    
    call _screen_hide_cursor
    
    mov r13, 0   ; r13 = huidige zichtbare regel (0 tot VP_H-1)
.line_loop:
    ; Bereken buffer regel index: VP_VIEW_Y + r13
    mov rax, [r12 + VP_VIEW_Y]
    add rax, r13
    cmp rax, [r12 + VP_BUF_H]
    jae .done_rendering
    
    ; Bereken start van regel in buffer
    mul qword [r12 + VP_W]
    add rax, [r12 + VP_BUF]
    mov r14, rax ; r14 = buffer regel pointer
    
    ; Zet cursor op fysieke schermpositie
    ; Rij = VP_Y + r13 + 1, Kolom = VP_X + 1
    mov rdi, [r12 + VP_Y]
    add rdi, r13
    inc rdi
    mov rsi, [r12 + VP_X]
    inc rsi
    call _cursor_goto_xy
    
    ; Schrijf de regel
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, r14
    mov rdx, [r12 + VP_W]
    syscall
    
    inc r13
    cmp r13, [r12 + VP_H]
    jb .line_loop

.done_rendering:
    call _screen_show_cursor
    @restore_context
    ret

; --- [ Scroll Viewport ] ---
; Input: RDI = VP_Ptr, RSI = Aantal (+/-)
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

; --- [ Algemene Functies ] ---
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
