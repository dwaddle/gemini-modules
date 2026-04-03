; test_screen_buffer.asm - Test for Non-destructive Virtual Screen Buffer
%include "algemeen.mac"

section .data
    msg_start  db "Virtual Screen Buffer Test (100 regels)", 10, 0
    msg_scroll db "Gebruik: Druk op een toets om 10 regels naar BENEDEN te schuiven (view down)", 0
    msg_up     db "Gedaan. Druk op een toets om 10 regels naar BOVEN te schuiven (view up)", 0
    msg_done   db "Klaar. Druk op een toets om te stoppen.", 0
    line_pref  db "Line #", 0
    line_suff  db " - Deze tekst blijft bewaard in de buffer!", 0

section .bss
    num_buf    resb 16

section .text
    global _start
    extern _screen_buffer_init, _screen_buffer_write, _screen_buffer_render, _screen_buffer_scroll_view
    extern PrintString, PrintNewline, ReadChar, _int_to_str

_start:
    ; 1. Initialiseer buffer voor 100 regels
    mov rdi, 100
    call _screen_buffer_init
    
    ; 2. Vul de buffer met 100 verschillende regels
    mov r12, 0
.fill_loop:
    ; Zet regelnummer in num_buf
    mov rax, r12
    mov rdi, num_buf
    call _int_to_str
    
    ; Schrijf "Line #"
    mov rdi, 2
    mov rsi, r12
    mov rdx, line_pref
    call _screen_buffer_write
    
    ; Schrijf het nummer
    mov rdi, 8
    mov rsi, r12
    mov rdx, num_buf
    call _screen_buffer_write
    
    ; Schrijf de suffix
    mov rdi, 12
    mov rsi, r12
    mov rdx, line_suff
    call _screen_buffer_write
    
    inc r12
    cmp r12, 100
    jb .fill_loop

    ; 3. Render de eerste 24 regels
    call _screen_buffer_render
    
    ; 4. Interactief gedeelte
    call ReadChar
    
    ; Scroll 10 regels omlaag (view gaat naar beneden)
    mov rdi, 10
    call _screen_buffer_scroll_view
    
    call ReadChar
    
    ; Scroll nog eens 20 regels omlaag
    mov rdi, 20
    call _screen_buffer_scroll_view
    
    call ReadChar
    
    ; Scroll 30 regels omhoog (terug naar boven)
    ; De oude regels (0-9) moeten nu weer verschijnen!
    mov rdi, -30
    call _screen_buffer_scroll_view
    
    call ReadChar
    
    @exit 0
