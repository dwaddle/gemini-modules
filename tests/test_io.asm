; test_io.asm - Test for IO Module
section .data
    msg_test1 db "Testing PrintString: Hello World!", 10, 0
    msg_test2 db "Testing PrintNewline:", 0

section .text
    global _start
    extern PrintString
    extern PrintNewline

_start:
    ; Test 1: PrintString
    mov rdi, msg_test1
    call PrintString

    ; Test 2: PrintNewline
    mov rdi, msg_test2
    call PrintString
    call PrintNewline
    
    ; Test 3: PrintString with a different string
    mov rdi, msg_test1
    call PrintString

    ; Exit
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; return code 0
    syscall
