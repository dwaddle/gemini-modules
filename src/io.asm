; ---------------------------------------------------------
; IO MODULE - Scherm en Tekst
; ---------------------------------------------------------
%include "syscalls.inc"
%include "algemeen.mac"

section .data
    esc_color_pre db 27, '[3', 0    ; Voorgrondkleur prefix (ESC[3[0-7]m)
    hex_chars     db "0123456789ABCDEF"
    hex_prefix    db "0x", 0
    
    ; Data voor PrintColorString
    cs_esc_pre    db 27, '[3', 0
    cs_color_char db '0', 'm', 0

section .text
global PrintString
global PrintNewline
global PrintInt
global PrintHex
global PrintColor
global PrintColorString
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

; --- [ Print String met Kleurcodes ] ---
; Parseert codes zoals |Y (Geel) en |y (Reset)
; Input: RDI = Adres van string
PrintColorString:
    @save_context
    mov r12, rdi        ; r12 = huidige pointer
    mov r13, rdi        ; r13 = start van huidig segment
.loop:
    mov al, [r12]
    test al, al
    jz .done_last
    
    cmp al, '|'
    jne .next
    
    ; 1. Print segment vóór de '|'
    mov rdx, r12
    sub rdx, r13        ; lengte segment
    jz .skip_segment
    
    mov rdi, 1          ; stdout
    mov rsi, r13
    mov rax, SYS_WRITE
    syscall
    
.skip_segment:
    inc r12             ; Sla '|' over
    mov al, [r12]
    test al, al
    jz .done            ; Onverwacht einde
    
    ; 2. Handel de code af
    cmp al, '|'
    je .literal_pipe
    
    ; Is het een reset code (kleine letter)?
    cmp al, 'a'
    jae .handle_reset
    
    ; Is het een kleur code (hoofdletter)?
    call .get_color_index
    cmp al, 0xFF
    je .invalid_code
    
    ; Print ANSI kleur code
    push rax
    mov rdi, cs_esc_pre
    call PrintString
    pop rax
    add al, '0'
    mov [cs_color_char], al
    mov rdi, cs_color_char
    call PrintString
    
    jmp .after_code

.handle_reset:
    extern _screen_reset_color
    call _screen_reset_color
    jmp .after_code

.literal_pipe:
    ; Print een enkele '|'
    push r12
    sub rsp, 8
    mov byte [rsp], '|'
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    add rsp, 8
    pop r12
    jmp .after_code

.invalid_code:
    jmp .after_code

.after_code:
    inc r12             ; Sla code karakter over
    mov r13, r12        ; Nieuw segment begint na de code
    jmp .loop

.next:
    inc r12
    jmp .loop

.done_last:
    mov rdx, r12
    sub rdx, r13
    jz .done
    mov rdi, 1
    mov rsi, r13
    mov rax, SYS_WRITE
    syscall

.done:
    @restore_context
    ret

; Helper: Map karakter in AL naar 0-7, of 0xFF indien ongeldig
.get_color_index:
    cmp al, 'K' ; Black
    je .c0
    cmp al, 'R' ; Red
    je .c1
    cmp al, 'G' ; Green
    je .c2
    cmp al, 'Y' ; Yellow
    je .c3
    cmp al, 'B' ; Blue
    je .c4
    cmp al, 'M' ; Magenta
    je .c5
    cmp al, 'C' ; Cyan
    je .c6
    cmp al, 'W' ; White
    je .c7
    mov al, 0xFF
    ret
.c0: mov al, 0
    ret
.c1: mov al, 1
    ret
.c2: mov al, 2
    ret
.c3: mov al, 3
    ret
.c4: mov al, 4
    ret
.c5: mov al, 5
    ret
.c6: mov al, 6
    ret
.c7: mov al, 7
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
