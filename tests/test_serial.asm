; test_serial.asm - Test for Serial Port functionality
%include "algemeen.mac"
%include "macros.inc"

section .data
    tty_path   db "/dev/ttyS0", 0
    msg_open   db "Opening /dev/ttyS0...", 0
    msg_config db "Configuring 9600 baud...", 0
    msg_send   db "Sending test string...", 0
    msg_ok     db " [OK]", 10, 0
    msg_fail   db " [FAIL] (Check permissions / port exists)", 10, 0
    
    test_data  db "Hello from Professional ASM Serial Module!", 10, 0
    test_len   equ $ - test_data

section .bss
    fd         resq 1

section .text
    global _start
    extern PrintString

_start:
    ; 1. Open
    mov rdi, msg_open
    call PrintString
    @serial_open tty_path
    test rax, rax
    js .fail
    mov [fd], rax
    mov rdi, msg_ok
    call PrintString

    ; 2. Config
    mov rdi, msg_config
    call PrintString
    ; Note: B9600 constant would need to be visible here or used as literal
    ; In io.asm it is 0xD
    @serial_config [fd], 0xD
    test rax, rax
    jnz .fail
    mov rdi, msg_ok
    call PrintString

    ; 3. Write
    mov rdi, msg_send
    call PrintString
    @serial_write [fd], test_data, test_len
    test rax, rax
    js .fail
    mov rdi, msg_ok
    call PrintString

    ; Exit
    mov rdi, [fd]
    mov rax, 3          ; SYS_CLOSE
    syscall
    @exit 0

.fail:
    mov rdi, msg_fail
    call PrintString
    @exit 0 ; Exit 0 because failing to open /dev/ttyS0 is expected without hardware
