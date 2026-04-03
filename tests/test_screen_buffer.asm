; test_screen_buffer.asm - Test for Virtual Buffer using Viewports
%include "algemeen.mac"
%include "screen.mac"

section .data
    msg_scroll db "Gebruik: Druk op een toets om 10 regels naar BENEDEN te schuiven", 0
    line_pref  db "Line #", 0
    line_suff  db " - Gecached in Viewport Buffer", 0

section .bss
    vp_test    resq 1
    num_buf    resb 16

section .text
    global _start
    extern _viewport_create, _viewport_write, _viewport_render, _viewport_scroll
    extern _screen_clear, PrintString, ReadChar, _int_to_str, _cursor_goto_xy

_start:
    call _screen_clear
    
    ; 1. Maak een viewport die het hele scherm vult (bijv. 80x24)
    @vp_create 0, 0, 80, 24, 100
    mov [vp_test], rax
    
    ; 2. Vul de buffer
    mov r12, 0
.fill_loop:
    mov rax, r12
    mov rdi, num_buf
    call _int_to_str
    
    @vp_write [vp_test], 2, r12, line_pref
    @vp_write [vp_test], 8, r12, num_buf
    @vp_write [vp_test], 12, r12, line_suff
    
    inc r12
    cmp r12, 100
    jb .fill_loop

    ; 3. Render
    @vp_render [vp_test]
    
    ; 4. Scrollen
    call ReadChar
    @vp_scroll [vp_test], 10
    
    call ReadChar
    @vp_scroll [vp_test], 20
    
    call ReadChar
    @vp_scroll [vp_test], -30
    
    call ReadChar
    @exit 0
