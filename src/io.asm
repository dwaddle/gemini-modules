; ---------------------------------------------------------
; IO MODULE - Scherm en Tekst
; ---------------------------------------------------------
%include "syscalls.inc"
%include "algemeen.mac"

section .data
    esc_color_pre db 27, '[3', 0    ; Voorgrondkleur prefix (ESC[3[0-7]m)
    hex_chars     db "0123456789ABCDEF"
    hex_prefix    db "0x", 0

section .text
global PrintString
global PrintNewline
global PrintInt
global PrintHex
global PrintColor
global ReadString
global ReadChar

extern _int_to_str

; --- [ Print String ] ---
; Input: RDI = Adres van null-terminated string
PrintString:
    @save_context
    mov rsi, rdi
    xor rdx, rdx
.len_loop:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .len_loop
.print:
    mov rdi, 1          ; stdout
    mov rax, SYS_WRITE
    syscall
    @restore_context
    ret

; --- [ Print Newline ] ---
PrintNewline:
    @save_context
    push 10
    mov rsi, rsp
    mov rdx, 1
    mov rdi, 1
    mov rax, SYS_WRITE
    syscall
    pop rax
    @restore_context
    ret

; --- [ Print Integer ] ---
; Input: RDI = Getal
PrintInt:
    @save_context
    sub rsp, 32         ; Buffer voor string
    mov rax, rdi
    mov rdi, rsp
    call _int_to_str
    mov rdi, rsp
    call PrintString
    add rsp, 32
    @restore_context
    ret

; --- [ Print Hexadecimaal ] ---
; Input: RDI = Waarde
PrintHex:
    @save_context
    push rdi
    mov rdi, hex_prefix
    call PrintString
    pop rdi
    
    sub rsp, 24         ; Ruimte voor 16 hex karakters + null
    mov rsi, rsp        ; RSI = buffer pointer
    mov rdx, rdi        ; RDX = waarde
    mov rcx, 16         ; 16 nibbles
.hex_loop:
    rol rdx, 4          ; Hoogste nibble naar laagste
    mov rax, rdx
    and rax, 0xF
    movzx rax, byte [hex_chars + rax]
    mov [rsi], al
    inc rsi
    loop .hex_loop
    
    mov byte [rsi], 0   ; Null-terminator
    mov rdi, rsp
    call PrintString
    add rsp, 24
    @restore_context
    ret

; --- [ Print in Kleur ] ---
; Input: RDI = String, RSI = Kleurcode (0-7)
PrintColor:
    @save_context
    push rdi            ; Bewaar string pointer
    
    ; 1. Stuur kleur escape code
    mov rdi, esc_color_pre
    call PrintString
    
    mov al, sil
    add al, '0'
    sub rsp, 8
    mov [rsp], al
    mov byte [rsp+1], 'm'
    mov byte [rsp+2], 0
    mov rdi, rsp
    call PrintString
    add rsp, 8
    
    ; 2. Print de string
    pop rdi
    call PrintString
    
    ; 3. Reset kleur
    extern _screen_reset_color
    call _screen_reset_color
    
    @restore_context
    ret

; --- [ Lees String ] ---
; Input: RDI = Buffer, RSI = Max Lengte
; Output: RAX = Aantal gelezen bytes
ReadString:
    @save_context
    mov rdx, rsi        ; Max lengte
    mov rsi, rdi        ; Buffer
    mov rdi, 0          ; stdin
    mov rax, SYS_READ
    syscall
    
    ; Null-terminate (vervang de newline indien aanwezig)
    test rax, rax
    js .done
    cmp byte [rsi + rax - 1], 10
    jne .terminate
    mov byte [rsi + rax - 1], 0
    dec rax
    jmp .done
.terminate:
    mov byte [rsi + rax], 0
.done:
    @restore_context
    ret

; --- [ Lees Karakter ] ---
; Wacht op één karakter (zonder enter als terminal in raw mode is, maar hier standaard)
ReadChar:
    @save_context
    sub rsp, 8
    mov rdi, 0          ; stdin
    mov rsi, rsp        ; buffer op stack
    mov rdx, 1
    mov rax, SYS_READ
    syscall
    movzx rax, byte [rsp]
    add rsp, 8
    @restore_context
    ret
