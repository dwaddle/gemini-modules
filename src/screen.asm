; screen.asm - Screen Control Functions (x86_64 Linux)
%include "algemeen.mac"

section .data
    esc_clear    db 27, '[2J', 27, '[H', 0  ; Wist scherm en zet cursor op home
    esc_reset    db 27, '[0m', 0           ; Reset alle kleuren en effecten
    esc_hide     db 27, '[?25l', 0         ; Verberg cursor
    esc_show     db 27, '[?25h', 0         ; Toon cursor
    esc_bg_pre   db 27, '[4', 0            ; Prefix voor achtergrondkleur (ESC[4[0-7]m)
    m_char       db 'm', 0
    esc_scroll_pre db 27, '[', 0

section .text
    global _screen_clear, _screen_reset_color, _screen_set_bgcolor, _screen_hide_cursor, _screen_show_cursor, _screen_scroll_up, _screen_scroll_down
    extern PrintString, _int_to_str

; ... (rest of functions) ...

; --- [ Scroll Up ] ---
; Input: RDI = Aantal regels
_screen_scroll_up:
    @save_context
    push 'S'
    jmp _screen_scroll_generic

; --- [ Scroll Down ] ---
; Input: RDI = Aantal regels
_screen_scroll_down:
    @save_context
    push 'T'

_screen_scroll_generic:
    mov rax, rdi        ; RDI was input
    sub rsp, 16
    mov rdi, rsp
    call _int_to_str
    
    ; Print ESC[
    mov rdi, esc_scroll_pre
    call PrintString
    
    ; Print count
    mov rdi, rsp
    call PrintString
    
    ; Print suffix ('S' of 'T')
    mov rbx, [rsp + 16] ; De 'S' of 'T' die we gepusht hebben
    mov [rsp], bl
    mov byte [rsp + 1], 0
    mov rdi, rsp
    call PrintString
    
    add rsp, 16
    pop rax             ; Verwijder gepushte suffix van stack
    @restore_context
    ret

; --- [ Wist Scherm ] ---
_screen_clear:
    mov rdi, esc_clear
    call PrintString
    ret

; --- [ Reset Kleuren ] ---
_screen_reset_color:
    mov rdi, esc_reset
    call PrintString
    ret

; --- [ Verberg Cursor ] ---
_screen_hide_cursor:
    mov rdi, esc_hide
    call PrintString
    ret

; --- [ Toon Cursor ] ---
_screen_show_cursor:
    mov rdi, esc_show
    call PrintString
    ret

; --- [ Stel Achtergrondkleur in ] ---
; Input: RDI = Kleurcode (0-7: Zwart, Rood, Groen, Geel, Blauw, Magenta, Cyaan, Wit)
_screen_set_bgcolor:
    @save_context
    push rdi
    
    mov rdi, esc_bg_pre
    call PrintString
    
    pop rdi
    add dil, '0'
    mov [m_char-1], dil ; (Dit is gevaarlijk, laten we het netter doen)
    ; Laten we een kleine buffer gebruiken
    sub rsp, 8
    mov byte [rsp], dil
    mov byte [rsp+1], 'm'
    mov byte [rsp+2], 0
    mov rdi, rsp
    call PrintString
    add rsp, 8
    
    @restore_context
    ret
