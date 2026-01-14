; ---------------------------------------------------------
; IO MODULE - Scherm en Tekst
; ---------------------------------------------------------
section .text
global PrintString
global PrintNewline

; Input: RDI = Adres van null-terminated string
PrintString:
    push rdi
    push rsi
    push rdx
    push rax

    ; 1. Bereken lengte (strlen)
    mov rsi, rdi        ; RSI = start adres
    xor rdx, rdx        ; RDX zal de teller zijn
.len_loop:
    cmp byte [rdi], 0   ; Check voor null-terminator
    je .print
    inc rdi
    inc rdx
    jmp .len_loop

.print:
    mov rdi, 1          ; FD 1 = stdout
    mov rax, 1          ; syscall: sys_write
    ; RSI staat al op het beginadres, RDX bevat de lengte
    syscall

    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

PrintNewline:
    push rax
    push rdi
    push rsi
    push rdx
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    push 10             ; Push newline (\n) op stack
    mov rsi, rsp        ; Gebruik stack adres als buffer
    mov rdx, 1          ; 1 byte
    syscall
    pop rax             ; Herstel stack
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
