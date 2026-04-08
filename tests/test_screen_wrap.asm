; tests/test_screen_wrap.asm - Unit tests for viewport word wrap

%include "screen.mac"
%include "string.mac"
%include "memory.mac"
%include "algemeen.mac"

section .data
    msg_test_passed db "Word wrap tests passed!", 10, 0
    msg_test_failed db "Word wrap tests failed!", 10, 0

    ; Viewport parameters for tests
    T_VP_X equ 1
    T_VP_Y equ 1
    T_VP_W equ 20 ; Narrow width for easier testing
    T_VP_H equ 5
    T_VP_BUF_H equ 10

    ; Test strings
    long_string db "This is a very long string that should definitely wrap around multiple times within the viewport to test the word wrap functionality correctly.", 0
    exact_fit_string db "This string fits exactly.", 0
    long_word_string db "Thisisareallylongwordthatwillnotwrapandshouldbetruncated", 0
    multiple_spaces_string db "This string   has   multiple    spaces.", 0

section .bss
    viewport_ptr resq 1

section .text
    global _start
    extern PrintString
    extern _viewport_create, _viewport_write, _viewport_render

_start:
    ; Create a viewport for testing
    mov rdi, T_VP_X
    mov rsi, T_VP_Y
    mov rdx, T_VP_W
    mov rcx, T_VP_H
    mov r8, T_VP_BUF_H
    call _viewport_create
    mov [viewport_ptr], rax

    ; --- Test 1: Basic word wrapping ---
    mov rdi, [viewport_ptr]
    mov rsi, 0          ; LX = 0
    mov rdx, 0          ; LY = 0
    mov rcx, long_string
    call _viewport_write

    mov rdi, [viewport_ptr]
    call _viewport_render

    ; --- Test 2: String that fits exactly ---
    mov rdi, [viewport_ptr]
    mov rsi, 0
    mov rdx, 0
    mov rcx, exact_fit_string
    call _viewport_write

    mov rdi, [viewport_ptr]
    call _viewport_render

    ; --- Test 3: Long word exceeding viewport width ---
    mov rdi, [viewport_ptr]
    mov rsi, 0
    mov rdx, 2 ; Start on line 2
    mov rcx, long_word_string
    call _viewport_write

    mov rdi, [viewport_ptr]
    call _viewport_render

    ; --- Test 4: Multiple spaces ---
    mov rdi, [viewport_ptr]
    mov rsi, 0
    mov rdx, 3 ; Start on line 3
    mov rcx, multiple_spaces_string
    call _viewport_write

    mov rdi, [viewport_ptr]
    call _viewport_render

    ; --- Test 5: Initial LX not at 0 ---
    mov rdi, [viewport_ptr]
    mov rsi, 5          ; Start at LX = 5
    mov rdx, 4          ; Start on line 4
    mov rcx, long_string
    call _viewport_write

    mov rdi, [viewport_ptr]
    call _viewport_render

    ; Success message
    mov rdi, msg_test_passed
    call PrintString
    
    mov rax, 60             ; SYS_EXIT
    xor rdi, rdi            ; Exit code 0
    syscall
