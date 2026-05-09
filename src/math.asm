; math.asm - Wiskundige functies voor x86_64
%include "algemeen.mac"

section .data
    seed dq 1234567890123456789

section .text
    global _math_rand
    global _math_rand_seed

; --- [ Math: Random Seed ] ---
; Input: RDI = Nieuwe seed waarde
_math_rand_seed:
    mov [seed], rdi
    ret

; --- [ Math: Random Number (Xorshift64) ] ---
; Output: RAX = Random 64-bit integer
_math_rand:
    mov rax, [seed]
    mov rdx, rax
    shl rdx, 13
    xor rax, rdx
    mov rdx, rax
    shr rdx, 7
    xor rax, rdx
    mov rdx, rax
    shl rdx, 17
    xor rax, rdx
    mov [seed], rax
    ret
