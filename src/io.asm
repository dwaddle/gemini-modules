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
    cs_256_pre    db 27, '[38;5;', 0
    cs_suffix     db 'm', 0

section .bss
    cs_num_buf    resb 16

section .text
global PrintString
global PrintNewline
global PrintInt
global PrintHex
global PrintColor
global PrintColorString
global ReadString
global ReadChar

extern _int_to_str, _strlen

; --- [ Print String ] ---
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
    mov rdi, 1
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
PrintInt:
    @save_context
    sub rsp, 32
    mov rax, rdi
    mov rdi, rsp
    call _int_to_str
    mov rdi, rsp
    call PrintString
    add rsp, 32
    @restore_context
    ret

; --- [ Print Hexadecimaal ] ---
PrintHex:
    @save_context
    push rdi
    mov rdi, hex_prefix
    call PrintString
    pop rdi
    sub rsp, 24
    mov rsi, rsp
    mov rdx, rdi
    mov rcx, 16
.hex_loop:
    rol rdx, 4
    mov rax, rdx
    and rax, 0xF
    movzx rax, byte [hex_chars + rax]
    mov [rsi], al
    inc rsi
    loop .hex_loop
    mov byte [rsi], 0
    mov rdi, rsp
    call PrintString
    add rsp, 24
    @restore_context
    ret

; --- [ Print in Kleur (Direct) ] ---
PrintColor:
    @save_context
    push rdi
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
    pop rdi
    call PrintString
    extern _screen_reset_color
    call _screen_reset_color
    @restore_context
    ret

; --- [ Print String met Uitgebreide Kleurcodes ] ---
; Syntax:
; |R, |G, ...  : Standaard 8 kleuren (0-7)
; |r, |g, ...  : Heldere 8 kleuren (8-15)
; |[n]         : 256 kleuren palette (0-255)
; |!           : Reset naar standaard
; |n           : Newline
; ||           : Letterlijke pipe
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
    sub rdx, r13
    jz .skip_segment
    mov rdi, 1
    mov rsi, r13
    mov rax, SYS_WRITE
    syscall
    
.skip_segment:
    inc r12
    mov al, [r12]
    test al, al
    jz .done
    
    cmp al, '|'
    je .literal_pipe
    cmp al, '!'
    je .handle_reset
    cmp al, 'n'
    je .handle_newline
    cmp al, '['
    je .handle_256
    
    ; Check voor basis kleuren (A-Z of a-z)
    cmp al, 'A'
    jb .invalid_code
    cmp al, 'z'
    ja .invalid_code
    
    ; Bepaal of het Bright is (kleine letter)
    mov rbx, 0          ; Offset
    cmp al, 'a'
    jb .not_bright
    sub al, 32          ; Convert naar hoofdletter
    mov rbx, 60         ; ANSI offset voor bright
.not_bright:
    call .get_color_index
    cmp al, 0xFF
    je .invalid_code
    
    ; Print ANSI code
    add rax, rbx
    push rax
    mov rdi, cs_esc_pre
    call PrintString
    pop rax
    sub rsp, 16
    mov rdi, rsp
    call _int_to_str
    mov rdi, rsp
    call PrintString
    mov rdi, cs_suffix
    call PrintString
    add rsp, 16
    jmp .after_code

.handle_reset:
    extern _screen_reset_color
    call _screen_reset_color
    jmp .after_code

.handle_newline:
    call PrintNewline
    jmp .after_code

.handle_256:
    inc r12             ; Sla '[' over
    xor rax, rax
    xor rcx, rcx
.parse_256_loop:
    mov cl, [r12]
    cmp cl, '0'
    jb .parse_256_done
    cmp cl, '9'
    ja .parse_256_done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc r12
    jmp .parse_256_loop
.parse_256_done:
    cmp byte [r12], ']'
    jne .invalid_code
    push rax
    mov rdi, cs_256_pre
    call PrintString
    pop rax
    mov rdi, cs_num_buf
    call _int_to_str
    mov rdi, cs_num_buf
    call PrintString
    mov rdi, cs_suffix
    call PrintString
    jmp .after_code

.literal_pipe:
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
    inc r12
    mov r13, r12
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

.get_color_index:
    cmp al, 'K'
    je .c0
    cmp al, 'R'
    je .c1
    cmp al, 'G'
    je .c2
    cmp al, 'Y'
    je .c3
    cmp al, 'B'
    je .c4
    cmp al, 'M'
    je .c5
    cmp al, 'C'
    je .c6
    cmp al, 'W'
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
ReadString:
    @save_context
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, 0
    mov rax, SYS_READ
    syscall
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
ReadChar:
    @save_context
    sub rsp, 8
    mov rdi, 0
    mov rsi, rsp
    mov rdx, 1
    mov rax, SYS_READ
    syscall
    movzx rax, byte [rsp]
    add rsp, 8
    @restore_context
    ret
