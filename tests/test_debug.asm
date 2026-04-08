; test_debug.asm - Test for Debug Module
%include "algemeen.mac"
%include "debug.mac"

section .text
    global _start

_start:
    ; Vul wat registers met herkenbare waarden (binnen 64-bit bounds)
    mov rax, 0x1111111111111111
    mov rbx, 0x2222222222222222
    mov rcx, 0x3333333333333333
    mov rdx, 0x4444444444444444
    mov rsi, 0x5555555555555555
    mov rdi, 0x6666666666666666
    mov r8,  0x8888888888888888
    mov r15, 0xF15F15F15F15F15F

    ; Roep de dumper aan
    @dump_regs

    ; Controleer of registers nog steeds dezelfde waarde hebben (context preservation test)
    mov r12, 0x1111111111111111
    cmp rax, r12
    jne .error
    
    mov rax, 60         ; SYS_EXIT
    xor rdi, rdi        ; code 0
    syscall

.error:
    mov rax, 60
    mov rdi, 1
    syscall
