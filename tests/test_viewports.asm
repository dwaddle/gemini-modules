; test_viewports.asm - Test for Multiple Viewports with Colors and Borders
%include "algemeen.mac"
%include "screen.mac"

section .data
    msg_start   db "Viewport Demo: Sidebar (rand) en Main (kleur)", 0
    sidebar_txt db "SIDEBAR", 0
    main_txt    db "MAIN CONTENT LINE #", 0
    press_key   db "Druk op een toets om RECHTS te scrollen...", 0

section .bss
    vp_sidebar resq 1
    vp_main    resq 1
    num_buf    resb 16

section .text
    global _start
    extern _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_set_color, _viewport_set_border
    extern _screen_clear, PrintString, ReadChar, _int_to_str, _cursor_goto_xy

_start:
    call _screen_clear
    
    ; 1. Maak Sidebar (X=0, Y=0, W=15, H=15, BufH=15)
    @vp_create 0, 0, 15, 15, 15
    mov [vp_sidebar], rax
    @vp_set_border [vp_sidebar], 1
    @vp_set_color  [vp_sidebar], 3, 0 ; Yellow on Black
    
    ; 2. Maak Main Window (X=20, Y=0, W=55, H=15, BufH=100)
    @vp_create 20, 0, 55, 15, 100
    mov [vp_main], rax
    @vp_set_border [vp_main], 1
    @vp_set_color  [vp_main], 2, 4 ; Green on Blue
    
    ; 3. Vul Sidebar
    mov r12, 0
.fill_sidebar:
    @vp_write [vp_sidebar], 2, r12, sidebar_txt
    inc r12
    cmp r12, 15
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
    mov rdi, 20
    mov rsi, 1
    call _cursor_goto_xy
    mov rdi, press_key
    call PrintString
    
    call ReadChar
    
    ; Scroll Main Window
    @vp_scroll [vp_main], 10
    
    call ReadChar
    
    ; Scroll nog eens
    @vp_scroll [vp_main], 20
    
    call ReadChar
    
    @exit 0
