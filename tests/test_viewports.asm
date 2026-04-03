; test_viewports.asm - Test for Multiple Independent Viewports
%include "algemeen.mac"
%include "screen.mac"

section .data
    msg_start  db "Viewport Demo: Sidebar (links) en Main (rechts)", 0
    sidebar_txt db "SIDEBAR", 0
    main_txt    db "MAIN CONTENT LINE #", 0
    press_key   db "Druk op een toets om RECHTS te scrollen...", 0

section .bss
    vp_sidebar resq 1
    vp_main    resq 1
    num_buf    resb 16

section .text
    global _start
    extern _viewport_create, _viewport_write, _viewport_render, _viewport_scroll
    extern _screen_clear, PrintString, ReadChar, _int_to_str, _cursor_goto_xy

_start:
    call _screen_clear
    
    ; 1. Maak Sidebar (X=0, Y=0, W=20, H=20, BufH=20)
    @vp_create 0, 0, 20, 20, 20
    mov [vp_sidebar], rax
    
    ; 2. Maak Main Window (X=22, Y=0, W=55, H=20, BufH=100)
    @vp_create 22, 0, 55, 20, 100
    mov [vp_main], rax
    
    ; 3. Vul Sidebar
    mov r12, 0
.fill_sidebar:
    @vp_write [vp_sidebar], 2, r12, sidebar_txt
    inc r12
    cmp r12, 20
    jb .fill_sidebar
    
    ; 4. Vul Main Window met 100 regels
    mov r12, 0
.fill_main:
    mov rax, r12
    mov rdi, num_buf
    call _int_to_str
    
    @vp_write [vp_main], 2, r12, main_txt
    @vp_write [vp_main], 22, r12, num_buf
    
    inc r12
    cmp r12, 100
    jb .fill_main

    ; 5. Initial Render
    @vp_render [vp_sidebar]
    @vp_render [vp_main]
    
    ; 6. Interactie
    mov rdi, 22
    mov rsi, 1
    call _cursor_goto_xy
    mov rdi, press_key
    call PrintString
    
    call ReadChar
    
    ; Scroll alleen het rechter scherm 10 regels omlaag
    @vp_scroll [vp_main], 10
    
    call ReadChar
    
    ; Scroll nog 20 regels
    @vp_scroll [vp_main], 20
    
    call ReadChar
    
    ; Scroll Sidebar (die maar 20 regels heeft, dus scrollen doet niks)
    @vp_scroll [vp_sidebar], 5
    
    call ReadChar
    
    @exit 0
