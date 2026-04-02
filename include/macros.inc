; macros.inc - High-level abstractions for NASM x86_64

; Exit the program cleanly
%macro exit 1
    mov rax, 60         ; sys_exit
    mov rdi, %1         ; return code
    syscall
%endmacro

; Print a string literal immediately
%macro print_lit 1
    section .data
        %%str db %1, 0
        %%len equ $ - %%str
    section .text
        mov rax, 1      ; sys_write
        mov rdi, 1      ; stdout
        mov rsi, %%str
        mov rdx, %%len
        syscall
%endmacro

; Fast register zeroing
%macro clear 1
    xor %1, %1
%endmacro
