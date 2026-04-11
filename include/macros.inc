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

; --- Serial Port Macros ---
%macro @serial_open 1
    mov rdi, %1
    extern SerialOpen
    call SerialOpen
%endmacro

%macro @serial_config 2
    mov rdi, %1
    mov rsi, %2
    extern SerialConfig
    call SerialConfig
%endmacro

%macro @serial_write 3
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    extern SerialWrite
    call SerialWrite
%endmacro

%macro @serial_read 3
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    extern SerialRead
    call SerialRead
%endmacro
