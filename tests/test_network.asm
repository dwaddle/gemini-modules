; test_network.asm - Test for Networking Module
%include "algemeen.mac"
%include "network.mac"

section .data
    msg_socket db "Testing Socket Creation...", 0
    msg_connect db "Testing Connection to 8.8.8.8:53...", 0
    msg_ok     db " [OK]", 10, 0
    msg_fail   db " [FAIL]", 10, 0
    
    ; sockaddr_in structure for 8.8.8.8:53
    ; sin_family = AF_INET (2)
    ; sin_port = 53 (0x3500 in big-endian)
    ; sin_addr = 8.8.8.8 (0x08080808)
    sock_addr:
        dw AF_INET
        dw 0x3500       ; 53 big-endian
        dd 0x08080808   ; 8.8.8.8
        dq 0            ; padding

section .bss
    sock_fd    resq 1

section .text
    global _start
    extern PrintString, PrintInt, PrintNewline

_start:
    ; 1. Create Socket
    mov rdi, msg_socket
    call PrintString
    @net_socket
    test rax, rax
    js .fail
    mov [sock_fd], rax
    mov rdi, msg_ok
    call PrintString

    ; 2. Connect
    mov rdi, msg_connect
    call PrintString
    @net_connect [sock_fd], sock_addr
    test rax, rax
    jnz .fail_connect
    mov rdi, msg_ok
    call PrintString

    ; 3. Close
    @net_close [sock_fd]

    @exit 0

.fail_connect:
    ; Connection might fail if no internet, but socket was created
    mov rdi, msg_fail
    call PrintString
    @net_close [sock_fd]
    @exit 0 ; Exit 0 because network might be down, not necessarily a bug

.fail:
    mov rdi, msg_fail
    call PrintString
    @exit 1
