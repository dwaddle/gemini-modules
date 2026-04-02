; cursor.asm - Cursor Control Functions (x86_64 Linux)
%include "algemeen.mac"

section .data
    ; ANSI Escape Sequences
    esc_goto    db 27, '[', 0    ; Prefix voor ESC[row;colH
    esc_home    db 27, '[H', 0   ; ESC[H (Home)
    esc_save    db 27, '[s', 0   ; ESC[s (Save)
    esc_rest    db 27, '[u', 0   ; ESC[u (Restore)
    semicolon   db ';', 0
    suffix_h    db 'H', 0
    suffix_rel  db 0, 0          ; Voor relatieve beweging: [count][dir]

section .bss
    num_buf     resb 16

section .text
    global _cursor_goto_xy, _cursor_home, _cursor_save, _cursor_restore, _cursor_move_relative
    extern PrintString, _int_to_str

; --- [ Ga naar X, Y ] ---
; Input: RDI = Rij, RSI = Kolom
_cursor_goto_xy:
    @save_context
    push rsi            ; Bewaar kolom
    push rdi            ; Bewaar rij
    
    mov rdi, esc_goto
    call PrintString
    
    pop rax             ; Rij
    mov rdi, num_buf
    call _int_to_str
    mov rdi, num_buf
    call PrintString
    
    mov rdi, semicolon
    call PrintString
    
    pop rax             ; Kolom
    mov rdi, num_buf
    call _int_to_str
    mov rdi, num_buf
    call PrintString
    
    mov rdi, suffix_h
    call PrintString
    
    @restore_context
    ret

; --- [ Cursor naar Home (1,1) ] ---
_cursor_home:
    mov rdi, esc_home
    call PrintString
    ret

; --- [ Sla Cursor Positie op ] ---
_cursor_save:
    mov rdi, esc_save
    call PrintString
    ret

; --- [ Herstel Cursor Positie ] ---
_cursor_restore:
    mov rdi, esc_rest
    call PrintString
    ret

; --- [ Relatieve Beweging ] ---
; Input: RDI = Karakter ('A'=Omhoog, 'B'=Omlaag, 'C'=Rechts, 'D'=Links), RSI = Aantal
_cursor_move_relative:
    @save_context
    push rdi            ; Richting
    
    mov rdi, esc_goto   ; Gebruik ESC[ prefix
    call PrintString
    
    mov rax, rsi        ; Aantal
    mov rdi, num_buf
    call _int_to_str
    mov rdi, num_buf
    call PrintString
    
    pop rdi             ; Richting karakter
    mov [suffix_rel], dil
    mov byte [suffix_rel+1], 0
    mov rdi, suffix_rel
    call PrintString
    
    @restore_context
    ret
