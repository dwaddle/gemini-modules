; test_io_v2.asm - Test for Expanded IO, Screen and Cursor
%include "algemeen.mac"

section .data
    msg_hex    db "Hex test (0x12345678): ", 0
    msg_int    db "Int test (1337): ", 0
    msg_color  db "Color test (Green)", 0
    msg_cursor db "Cursor test (Moving to 5, 5 and printing 'X')", 0
    msg_scroll db "Full Screen Scroll Test: Printing 20 lines...", 10, 0
    msg_line   db "Dit is test-regel nummer: ", 0
    msg_up     db "Geprint. Druk op een toets om 10 regels OMHOOG te scrollen.", 0
    msg_down   db "Gedaan. Druk op een toets om 10 regels OMLAAG te scrollen.", 0
    msg_done   db "Klaar. Druk op een toets om te stoppen.", 0

section .text
    global _start
    extern PrintString, PrintNewline, PrintHex, PrintInt, PrintColor, ReadChar
    extern _screen_clear, _cursor_goto_xy, _screen_scroll_up, _screen_scroll_down

_start:
    call _screen_clear
    
    ; 1. Hex
    mov rdi, msg_hex
    call PrintString
    mov rdi, 0x12345678
    call PrintHex
    call PrintNewline
    
    ; 2. Int
    mov rdi, msg_int
    call PrintString
    mov rdi, 1337
    call PrintInt
    call PrintNewline
    
    ; 3. Color
    mov rdi, msg_color
    mov rsi, 2          ; Groen
    call PrintColor
    call PrintNewline
    
    ; 4. Cursor
    mov rdi, msg_cursor
    call PrintString
    mov rdi, 5
    mov rsi, 5
    call _cursor_goto_xy
    mov rdi, buffer_x
    mov byte [rdi], 'X'
    mov byte [rdi+1], 0
    call PrintString
    call PrintNewline
    
    ; 5. Full Screen Scroll Test
    call PrintNewline
    mov rdi, msg_scroll
    call PrintString
    
    ; Print 20 regels
    mov rcx, 1
.loop_lines:
    push rcx
    mov rdi, msg_line
    call PrintString
    pop rcx
    push rcx
    mov rdi, rcx
    call PrintInt
    call PrintNewline
    pop rcx
    inc rcx
    cmp rcx, 21
    jne .loop_lines
    
    ; Wacht op user
    mov rdi, msg_up
    call PrintString
    call ReadChar
    
    ; Scroll 10 omhoog
    mov rdi, 10
    call _screen_scroll_up
    
    ; Wacht op user
    mov rdi, msg_down
    call PrintString
    call ReadChar
    
    ; Scroll 10 omlaag
    mov rdi, 10
    call _screen_scroll_down
    
    ; 6. Done
    mov rdi, msg_done
    call PrintString
    call ReadChar
    
    @exit 0

section .bss
    buffer_x resb 2
