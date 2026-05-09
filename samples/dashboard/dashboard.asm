; dashboard.asm - Modern x86_64 Dashboard Example
%include "algemeen.mac"
%include "screen.mac"
%include "screen_constants.inc"
%include "string.mac"
%include "memory.mac"

section .data
    vp_title    db "SYSTEM MONITOR v2.0", 0
    status_lbl  db "Status: ", 0
    status_val  db "ONLINE", 0
    mem_lbl     db "Memory: ", 0
    buffer_msg  db "Virtual Viewport Active", 0
    press_key   db "Press any key to scroll...", 0
    footer      db "Copyright (c) 2026 - Professional ASM Modules", 0

section .bss
    vp_main     resq 1
    num_buf     resb 32

section .text
    global _start
    extern PrintString, PrintNewline, PrintInt, PrintColor, ReadChar, _int_to_str
    extern _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_set_color, _viewport_set_border, _viewport_set_title
    extern _cursor_goto_xy, _screen_clear

_start:
    call _screen_clear

    ; 1. Initialiseer Viewport (X=0, Y=0, W=80, H=20, BufH=100)
    mov rdi, 0 ; X
    mov rsi, 0 ; Y
    mov rdx, 80 ; W
    mov rcx, 20 ; H
    mov r8, 100 ; BufH
    call _viewport_create
    mov [vp_main], rax
    
    ; Stel kleur, border en TITEL in
    mov rdi, [vp_main]
    mov rsi, COL_WHITE
    mov rdx, COL_BLUE
    call _viewport_set_color
    
    mov rdi, [vp_main]
    mov rsi, VPF_BORDER
    call _viewport_set_border

    mov rdi, [vp_main]
    mov rsi, vp_title
    call _viewport_set_title

    ; 2. Bouw de inhoud op (zonder de titel, die doet de border nu)
    mov rdi, [vp_main]
    mov rsi, 5
    mov rdx, 3
    mov rcx, status_lbl
    call _viewport_write
    
    mov rdi, [vp_main]
    mov rsi, 13
    mov rdx, 3
    mov rcx, status_val
    call _viewport_write

    ; Voeg wat dummy data toe aan de viewport geschiedenis
    mov r12, 5
.data_loop:
    mov rax, r12
    mov rdi, num_buf
    call _int_to_str
    
    mov rdi, [vp_main]
    mov rsi, 5          ; LX
    mov rdx, r12        ; LY
    mov rcx, num_buf
    call _viewport_write

    mov rdi, [vp_main]
    mov rsi, 15
    mov rdx, r12
    mov rcx, buffer_msg
    call _viewport_write
    
    inc r12
    cmp r12, 90
    jb .data_loop

    ; Footer aan het einde van de buffer
    mov rdi, [vp_main]
    mov rsi, 5
    mov rdx, 95
    mov rcx, footer
    call _viewport_write

    ; 3. Eerste render
    mov rdi, [vp_main]
    call _viewport_render

    ; 4. Interactieve demo
    mov rdi, 22
    mov rsi, 1
    call _cursor_goto_xy
    mov rdi, press_key
    call PrintString
    
    call ReadChar

    ; Scroll 10 regels naar beneden
    mov rdi, [vp_main]
    mov rsi, 10
    call _viewport_scroll

    mov rdi, 23
    mov rsi, 1
    call _cursor_goto_xy
    mov rdi, footer
    call PrintString
    call PrintNewline
    
    call ReadChar

    @exit 0
