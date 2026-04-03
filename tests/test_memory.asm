; test_memory.asm - Test for Memory Module
%include "algemeen.mac"

section .data
    msg_alloc db "Test: MemAlloc (1024 bytes)", 0
    msg_copy  db "Test: MemCopy", 0
    msg_set   db "Test: MemSet", 0
    msg_cmp   db "Test: MemCompare", 0
    msg_ok    db " [OK]", 10, 0
    msg_fail  db " [FAIL]", 10, 0
    
    src_data  db "ABCDEFGHIJ", 0 ; 10 chars + null

section .bss
    dest_buf  resb 16

section .text
    global _start
    extern _mem_alloc, _mem_copy, _mem_set, _mem_compare
    extern PrintString, PrintHex

_start:
    ; 1. Alloc
    mov rdi, msg_alloc
    call PrintString
    mov rdi, 1024
    call _mem_alloc
    test rax, rax
    jz .fail
    ; Toon adres voor debug
    mov rdi, rax
    call PrintHex
    call .pass

    ; 2. Set
    mov rdi, msg_set
    call PrintString
    mov rdi, dest_buf
    mov rsi, 'X'
    mov rdx, 10
    call _mem_set
    ; Check first byte
    cmp byte [dest_buf], 'X'
    jne .fail
    call .pass

    ; 3. Copy
    mov rdi, msg_copy
    call PrintString
    mov rdi, dest_buf
    mov rsi, src_data
    mov rdx, 11
    call _mem_copy
    ; Check if copied
    mov rdi, dest_buf
    call PrintString
    call .pass

    ; 4. Compare
    mov rdi, msg_cmp
    call PrintString
    mov rdi, dest_buf
    mov rsi, src_data
    mov rdx, 11
    call _mem_compare
    test rax, rax
    jnz .fail
    call .pass

    @exit 0

.pass:
    mov rdi, msg_ok
    call PrintString
    ret

.fail:
    mov rdi, msg_fail
    call PrintString
    @exit 1
