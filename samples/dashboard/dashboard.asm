%include "linux_sys.mac"
%include "screen.mac"
%include "algemeen.mac"

section .data
    title    db "--- ASSEMBLER 64-BIT DASHBOARD ---", 0
    stat_msg db "Systeem Status: ", 0
    ok_msg   db "OPTIMAAL", 0
    val_msg  db "Huidige waarde: ", 0
    getal    dq 500

section .text
    global _start
    extern _print_str, _print_nl, _print_int, screen_clearscreen, screen_goto_xy, _print_color

_start:
    @cls                            ; Scherm wissen
    @move_cursor 2, 10              ; Rij 2, Kolom 10
    @println title                  ; Titel printen

    @move_cursor 4, 10
    @print_string stat_msg, 16
    @print_color ok_msg, green      ; Status in het groen

    @move_cursor 6, 10
    @print_string val_msg, 16
    
    ; Berekening: getal * 2
    mov rax, [getal]
    shl rax, 1                      ; Snelle vermenigvuldiging (shift left)
    @print_int rax                  ; Print resultaat (1000)

    @newline
    @move_cursor 10, 0
    @exit 0
