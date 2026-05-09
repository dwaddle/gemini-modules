; system.asm - Systeem en OS interactie voor x86_64
%include "algemeen.mac"

section .text
    global _sys_get_argc
    global _sys_get_argv

; --- [ System: Get Argument Count ] ---
; Input: RDI = Pointer naar de stack bij start (_start)
; Output: RAX = argc
_sys_get_argc:
    mov rax, [rdi]
    ret

; --- [ System: Get Argument Pointer ] ---
; Input: RDI = Pointer naar de stack bij start, RSI = Index
; Output: RAX = Pointer naar de string van argument[index]
_sys_get_argv:
    mov rax, [rdi]      ; RAX = argc
    cmp rsi, rax
    jae .out_of_bounds
    
    mov rax, [rdi + 8 + rsi * 8]
    ret

.out_of_bounds:
    xor rax, rax
    ret
