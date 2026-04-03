; test_io_v2.asm - Test for Expanded IO, Screen and Cursor
%include "algemeen.mac"

section .data
    msg_hex    db "Hex test (0x12345678): ", 0
    msg_int    db "Int test (1337): ", 0
    msg_color  db "Color test (Green)", 0
    msg_cursor db "Cursor test (Moving to 5, 5 and printing 'X')", 0
    msg_scroll db "Scroll test (Lijn 1 en 2 worden geprint, dan 1 omhoog)", 10, 0
    msg_line1  db "LIJN 1 (Verdwijnt bij scroll up)", 10, 0
    msg_line2  db "LIJN 2", 10, 0
    msg_done   db "IO v2 Tests complete. Press any key to finish.", 0

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
    
    ; 5. Scroll test
    call PrintNewline
    mov rdi, msg_scroll
    call PrintString
    mov rdi, msg_line1
    call PrintString
    mov rdi, msg_line2
    call PrintString
    
    ; Wacht even
    call ReadChar
    
    ; Scroll omhoog (verdwijnt van boven)
    mov rdi, 1
    call _screen_scroll_up
    
    ; 6. ReadChar
    mov rdi, 15
    mov rsi, 1
    call _cursor_goto_xy
    mov rdi, msg_done
    call PrintString
    call ReadChar
    
    @exit 0

section .bss
    buffer_x resb 2
