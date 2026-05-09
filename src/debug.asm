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
    global _debug_hex_dump
    extern PrintString, PrintHex, PrintNewline

; --- [ Debug: Hex Dump ] ---
; Input: RDI = Pointer to memory, RSI = Length in bytes
_debug_hex_dump:
    @save_context
    mov r12, rdi        ; R12 = Current pointer
    mov r13, rsi        ; R13 = Remaining length
    mov r14, 0          ; R14 = Offset in line

.line_loop:
    test r13, r13
    jz .done

    ; Print offset/address
    mov rdi, r12
    call PrintHex
    mov rdi, .space
    call PrintString

    ; Print hex bytes
    mov r14, 0
.hex_loop:
    cmp r14, 16
    jae .hex_done
    cmp r14, r13
    jae .pad_hex

    movzx rdi, byte [r12 + r14]
    call .print_byte_hex
    mov rdi, .space
    call PrintString
    
    inc r14
    jmp .hex_loop

.pad_hex:
    mov rdi, .padding
    call PrintString
    inc r14
    jmp .hex_loop

.hex_done:
    mov rdi, .bar
    call PrintString

    ; Print ASCII
    mov r14, 0
.ascii_loop:
    cmp r14, 16
    jae .ascii_done
    cmp r14, r13
    jae .ascii_done

    movzx rax, byte [r12 + r14]
    cmp al, 32
    jb .non_printable
    cmp al, 126
    ja .non_printable
    jmp .print_ascii

.non_printable:
    mov al, '.'

.print_ascii:
    push rax
    sub rsp, 8
    mov [rsp], al
    mov byte [rsp+1], 0
    mov rdi, rsp
    call PrintString
    add rsp, 8
    pop rax
    
    inc r14
    jmp .ascii_loop

.ascii_done:
    call PrintNewline
    
    ; Advance
    mov rax, 16
    cmp r13, 16
    jbe .set_zero
    sub r13, 16
    add r12, 16
    jmp .line_loop

.set_zero:
    xor r13, r13
    jmp .line_loop

.done:
    @restore_context
    ret

.print_byte_hex:
    push rbx
    push rcx
    push rdx
    mov rbx, rdi
    shr rdi, 4
    and rdi, 0x0F
    movzx rdi, byte [hex_chars + rdi]
    call .putc
    mov rdi, rbx
    and rdi, 0x0F
    movzx rdi, byte [hex_chars + rdi]
    call .putc
    pop rdx
    pop rcx
    pop rbx
    ret

.putc:
    sub rsp, 8
    mov [rsp], dil
    mov byte [rsp+1], 0
    mov rdi, rsp
    call PrintString
    add rsp, 8
    ret

section .data
    .space db " ", 0
    .padding db "   ", 0
    .bar db "| ", 0
    hex_chars db "0123456789ABCDEF"

section .text
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
