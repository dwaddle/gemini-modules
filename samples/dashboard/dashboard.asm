; dashboard.asm - Modern x86_64 Dashboard Example
%include "algemeen.mac"
%include "screen.mac"
%include "string.mac"
%include "memory.mac"

section .data
    title       db "=== SYSTEM MONITOR v2.0 ===", 0
    status_lbl  db "Status: ", 0
    status_val  db "ONLINE", 0
    mem_lbl     db "Memory: ", 0
    buffer_msg  db "Virtual Screen Buffer Active", 0
    press_key   db "Press any key to scroll...", 0
    footer      db "Copyright (c) 2026 - Gemini Modules", 0

section .bss
    num_buf     resb 32

section .text
    global _start
    extern PrintString, PrintNewline, PrintInt, PrintColor, ReadChar, _int_to_str
    extern _screen_buffer_init, _screen_buffer_write, _screen_buffer_render, _screen_buffer_scroll_view, _cursor_goto_xy

_start:
    ; 1. Initialiseer de buffer (50 regels voor geschiedenis)
    mov rdi, 50
    call _screen_buffer_init

    ; 2. Bouw het scherm op in de buffer
    ; Titel
    mov rdi, 25         ; X
    mov rsi, 1          ; Y
    mov rdx, title
    call _screen_buffer_write

    ; Status regel
    mov rdi, 5
    mov rsi, 3
    mov rdx, status_lbl
    call _screen_buffer_write
    
    mov rdi, 13
    mov rsi, 3
    mov rdx, status_val
    call _screen_buffer_write

    ; Voeg wat dummy data toe aan de buffer geschiedenis
    mov r12, 10
.data_loop:
    mov rax, r12
    mov rdi, num_buf
    call _int_to_str
    
    mov rdi, 5
    mov rsi, r12
    mov rdx, num_buf
    call _screen_buffer_write
    
    mov rdi, 15
    mov rsi, r12
    mov rdx, buffer_msg
    call _screen_buffer_write
    
    inc r12
    cmp r12, 40
    jb .data_loop

    ; Footer
    mov rdi, 5
    mov rsi, 45
    mov rdx, footer
    call _screen_buffer_write

    ; 3. Eerste render
    call _screen_buffer_render

    ; 4. Interactieve demo
    ; Verplaats cursor naar beneden voor melding
    mov rdi, 22
    mov rsi, 1
    call _cursor_goto_xy
    mov rdi, press_key
    call PrintString
    
    call ReadChar

    ; Scroll 5 regels
    mov rdi, 5
    call _screen_buffer_scroll_view

    mov rdi, 22
    mov rsi, 1
    call _cursor_goto_xy
    mov rdi, footer
    call PrintString
    call PrintNewline
    
    call ReadChar

    @exit 0
