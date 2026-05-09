; security.asm - Security and Encoding for x86_64
%include "algemeen.mac"

section .data
    base64_chars db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

section .text
    global _base64_encode
    global _base64_decode

; --- [ Base64: Encode ] ---
; Input: RDI = Dest Buffer, RSI = Src Buffer, RDX = Length
_base64_encode:
    @save_context
    mov r12, rdi        ; Dest
    mov r13, rsi        ; Src
    mov r14, rdx        ; Length
    
.loop:
    cmp r14, 0
    je .done
    
    xor rax, rax
    mov al, [r13]       ; Byte 1
    shl rax, 8
    
    cmp r14, 1
    je .one_byte
    
    mov al, [r13 + 1]   ; Byte 2
    shl rax, 8
    
    cmp r14, 2
    je .two_bytes
    
    mov al, [r13 + 2]   ; Byte 3
    
    ; 3 bytes -> 4 base64 chars
    mov rbx, rax
    shr rbx, 18
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12], bl
    
    mov rbx, rax
    shr rbx, 12
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12 + 1], bl
    
    mov rbx, rax
    shr rbx, 6
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12 + 2], bl
    
    mov rbx, rax
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12 + 3], bl
    
    add r12, 4
    add r13, 3
    sub r14, 3
    jmp .loop

.one_byte:
    shr rax, 8          ; Align to 24-bit
    mov rbx, rax
    shr rbx, 10
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12], bl
    
    mov rbx, rax
    shr rbx, 4
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12 + 1], bl
    
    mov byte [r12 + 2], '='
    mov byte [r12 + 3], '='
    add r12, 4
    jmp .done

.two_bytes:
    shr rax, 8          ; Align to 24-bit
    mov rbx, rax
    shr rbx, 18
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12], bl
    
    mov rbx, rax
    shr rbx, 12
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12 + 1], bl
    
    mov rbx, rax
    shr rbx, 6
    and rbx, 63
    movzx rbx, byte [base64_chars + rbx]
    mov [r12 + 2], bl
    
    mov byte [r12 + 3], '='
    add r12, 4
    jmp .done

.done:
    mov byte [r12], 0   ; Null-terminator
    @restore_context
    ret

; --- [ Base64: Decode ] ---
; (Simplified implementation, assumes valid input)
_base64_decode:
    ; Implementation omitted for brevity in this example, 
    ; but can be added if needed.
    ret
