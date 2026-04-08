; debug.asm - Debugging and Inspection Tools
%include "algemeen.mac"

section .data
    ; Namen in volgorde van stack layout (top naar bottom)
    ; De macro @dump_regs doet:
    ;   @save_context (pusht RBX tot R15)
    ;   push rax
    ; Dus stack is: [RAX], [R15], [R14], [R13], [R12], [R11], [R10], [R9], [R8], [RBP], [RDI], [RSI], [RDX], [RCX], [RBX]
    
    reg_names:
        dq .rax, .r15, .r14, .r13, .r12, .r11, .r10, .r9
        dq .r8, .rbp, .rdi, .rsi, .rdx, .rcx, .rbx
    
    .rax db "RAX: ", 0
    .rbx db "RBX: ", 0
    .rcx db "RCX: ", 0
    .rdx db "RDX: ", 0
    .rbp db "RBP: ", 0
    .rsi db "RSI: ", 0
    .rdi db "RDI: ", 0
    .r8  db "R8 : ", 0
    .r9  db "R9 : ", 0
    .r10 db "R10: ", 0
    .r11 db "R11: ", 0
    .r12 db "R12: ", 0
    .r13 db "R13: ", 0
    .r14 db "R14: ", 0
    .r15 db "R15: ", 0

    header db "--- [ REGISTER DUMP ] ---", 10, 0
    footer db "-------------------------", 10, 0

section .text
    global _debug_dump_regs
    extern PrintString, PrintHex, PrintNewline

; --- [ Debug: Dump Registers ] ---
; Input: RDI = Pointer naar de opgeslagen registers op de stack
_debug_dump_regs:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    
    mov r12, rdi        ; R12 = pointer naar RAX op stack
    
    mov rdi, header
    call PrintString

    mov r13, 0          ; Index
.loop:
    ; Print naam
    mov rax, [reg_names + r13 * 8]
    mov rdi, rax
    call PrintString
    
    ; Print waarde
    mov rdi, [r12 + r13 * 8]
    call PrintHex
    call PrintNewline
    
    inc r13
    cmp r13, 15         ; We hebben 15 registers opgeslagen (RAX + 14 van context)
    jl .loop

    mov rdi, footer
    call PrintString
    
    pop r13
    pop r12
    pop rbp
    ret
