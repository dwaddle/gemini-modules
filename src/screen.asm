; screen.asm - Screen Control Functions with Virtual Buffer (x86_64 Linux)
%include "algemeen.mac"
%include "syscalls.inc"

section .data
    esc_clear       db 27, '[2J', 27, '[H', 0
    esc_reset       db 27, '[0m', 0
    esc_hide        db 27, '[?25l', 0
    esc_show        db 27, '[?25h', 0
    esc_bg_pre      db 27, '[4', 0
    esc_scroll_pre  db 27, '[', 0

    ; Buffer Data
    v_buffer_ptr    dq 0
    v_buffer_width  dq 80
    v_buffer_height dq 0
    v_view_y        dq 0                     ; Huidige scroll positie (start rij)
    v_screen_height dq 24                    ; Aantal zichtbare regels (veiligheidsmarge)

section .text
    global _screen_clear, _screen_reset_color, _screen_set_bgcolor, _screen_hide_cursor, _screen_show_cursor
    global _screen_scroll_up, _screen_scroll_down
    global _screen_buffer_init, _screen_buffer_write, _screen_buffer_render, _screen_buffer_scroll_view, _screen_buffer_clear
    
    extern PrintString, _int_to_str, _mem_alloc, _mem_set, _mem_copy, _cursor_goto_xy, _strlen

; --- [ Buffer Initialiseren ] ---
; Input: RDI = Aantal regels (Hoogte)
_screen_buffer_init:
    @save_context
    mov [v_buffer_height], rdi
    mov rax, rdi
    mul qword [v_buffer_width]
    mov rdi, rax
    call _mem_alloc
    mov [v_buffer_ptr], rax
    call _screen_buffer_clear
    @restore_context
    ret

; --- [ Buffer Leegmaken ] ---
_screen_buffer_clear:
    @save_context
    mov rax, [v_buffer_ptr]
    test rax, rax
    jz .done
    mov rdi, rax
    mov rsi, ' '
    mov rax, [v_buffer_height]
    mul qword [v_buffer_width]
    mov rdx, rax
    call _mem_set
.done:
    @restore_context
    ret

; --- [ Schrijf naar Buffer ] ---
; Input: RDI = X, RSI = Y, RDX = String Pointer
_screen_buffer_write:
    @save_context
    mov r12, rdi        ; X
    mov r13, rsi        ; Y
    mov r14, rdx        ; String Pointer
    
    mov rax, [v_buffer_ptr]
    test rax, rax
    jz .done

    ; 1. Bereken lengte
    mov rdi, r14
    call _strlen
    mov r15, rax        ; Lengte
    
    ; 2. Truncatie check (X + lengte mag niet voorbij breedte)
    mov rax, r12
    add rax, r15
    cmp rax, [v_buffer_width]
    jle .do_copy
    mov rax, [v_buffer_width]
    sub rax, r12
    mov r15, rax        ; Pas lengte aan
.do_copy:
    ; 3. Bereken offset in buffer: (Y * Width) + X
    mov rax, r13
    mul qword [v_buffer_width]
    add rax, r12
    add rax, [v_buffer_ptr]
    
    mov rdi, rax        ; Dest
    mov rsi, r14        ; Src
    mov rdx, r15        ; Count
    call _mem_copy
.done:
    @restore_context
    ret

; --- [ Render Buffer naar Scherm ] ---
_screen_buffer_render:
    @save_context
    mov rax, [v_buffer_ptr]
    test rax, rax
    jz .done
    
    call _screen_hide_cursor
    call _screen_clear
    
    mov r12, 0          ; r12 = huidige scherm-regel (0-23)
.line_loop:
    ; Bereken welke buffer-regel we tekenen: v_view_y + r12
    mov rax, [v_view_y]
    add rax, r12
    cmp rax, [v_buffer_height]
    jae .finish_render
    
    mul qword [v_buffer_width]
    add rax, [v_buffer_ptr]
    mov r13, rax        ; r13 = start van regel in buffer
    
    ; Zet cursor (Regel r12+1, Kolom 1)
    mov rdi, r12
    inc rdi
    mov rsi, 1
    call _cursor_goto_xy
    
    ; Schrijf de hele regel in één keer (veel sneller)
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, r13
    mov rdx, [v_buffer_width]
    syscall
    
    inc r12
    cmp r12, [v_screen_height]
    jb .line_loop

.finish_render:
    call _screen_show_cursor
.done:
    @restore_context
    ret

; --- [ Scroll View (Non-destructive) ] ---
; Input: RDI = Aantal regels om te verschuiven (+ naar beneden, - naar boven)
_screen_buffer_scroll_view:
    @save_context
    mov rax, [v_view_y]
    add rax, rdi
    
    ; Check ondergrens (0)
    test rax, rax
    js .set_zero
    
    ; Check bovengrens (max height - screen height)
    mov rbx, [v_buffer_height]
    sub rbx, [v_screen_height]
    cmp rax, rbx
    jle .update
    mov rax, rbx
    jmp .update
.set_zero:
    xor rax, rax
.update:
    mov [v_view_y], rax
    call _screen_buffer_render
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

_screen_scroll_up:
    @save_context
    mov rsi, 'S'
    call _screen_scroll_logic
    @restore_context
    ret

_screen_scroll_down:
    @save_context
    mov rsi, 'T'
    call _screen_scroll_logic
    @restore_context
    ret

_screen_scroll_logic:
    mov r12, rsi        ; Suffix
    mov rax, rdi        ; Aantal
    sub rsp, 16
    mov rdi, rsp
    call _int_to_str
    mov rdi, esc_scroll_pre
    call PrintString
    mov rdi, rsp
    call PrintString
    mov [rsp], r12b
    mov byte [rsp+1], 0
    mov rdi, rsp
    call PrintString
    add rsp, 16
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
