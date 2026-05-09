; test_new_modules.asm - Test for Debug Hex Dump, Math Rand, and System Argv
%include "algemeen.mac"
%include "debug.mac"
%include "math.mac"
%include "system.mac"
%include "list.mac"
%include "security.mac"

section .data
    msg_test_hex  db "Test: Hex Dump", 10, 0
    msg_test_rand db "Test: Random Numbers", 10, 0
    msg_test_argv db "Test: CLI Arguments", 10, 0
    msg_test_list db "Test: Linked List", 10, 0
    msg_test_b64  db "Test: Base64 Encode", 10, 0
    test_data     db "Hello Gemini! This is a test of the hex dump utility.", 0
    test_b64_src  db "Gemini", 0
    
    msg_argc      db "Argc: ", 0
    msg_argv0     db "Argv[0]: ", 0
    msg_list_val  db "List Val: ", 0
    msg_b64_res   db "B64 Result: ", 0
    msg_ok        db " [OK]", 10, 0
    msg_fail      db " [FAIL]", 10, 0

section .bss
    my_list       resq 1
    b64_buffer    resb 64

section .text
    global _start
    extern PrintString, PrintInt, PrintNewline, PrintHex

_start:
    ; Save initial stack pointer for system macros
    mov r12, rsp

    ; 1. Test Hex Dump
    mov rdi, msg_test_hex
    call PrintString
    @hex_dump test_data, 64
    call PrintNewline

    ; 2. Test Random Numbers
    mov rdi, msg_test_rand
    call PrintString
    
    @rand_seed 987654321
    mov rcx, 5
.rand_loop:
    push rcx
    @rand
    mov rdi, rax
    call PrintHex
    call PrintNewline
    pop rcx
    loop .rand_loop
    call PrintNewline

    ; 3. Test CLI Arguments
    mov rdi, msg_test_argv
    call PrintString
    
    @get_argc r12
    push rax
    mov rdi, msg_argc
    call PrintString
    pop rax
    mov rdi, rax
    call PrintInt
    call PrintNewline
    
    @get_argv r12, 0
    push rax
    mov rdi, msg_argv0
    call PrintString
    pop rax
    mov rdi, rax
    call PrintString
    call PrintNewline

    ; 4. Test Linked List
    mov rdi, msg_test_list
    call PrintString
    
    mov qword [my_list], 0
    @list_push_front my_list, 100
    @list_push_back my_list, 200
    @list_push_front my_list, 50
    
    ; Should be: 50 -> 100 -> 200
    
    mov rcx, 3
.list_loop:
    push rcx
    @list_pop_front my_list
    push rax
    mov rdi, msg_list_val
    call PrintString
    pop rax
    mov rdi, rax
    call PrintInt
    call PrintNewline
    pop rcx
    loop .list_loop

    @list_free my_list

    ; 5. Test Base64 Encode
    mov rdi, msg_test_b64
    call PrintString
    
    @base64_encode b64_buffer, test_b64_src, 6
    mov rdi, msg_b64_res
    call PrintString
    mov rdi, b64_buffer
    call PrintString
    call PrintNewline

    ; Exit
    @exit 0
