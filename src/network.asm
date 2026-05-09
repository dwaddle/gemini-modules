; network.asm - TCP/IP Networking for x86_64 Linux
%include "syscalls.inc"
%include "algemeen.mac"
%include "network_constants.inc"

section .text
    global _net_socket, _net_connect, _net_send, _net_recv, _net_close, _htons, _net_aton, _net_bind, _net_listen, _net_accept

; --- [ Create Socket ] ---
; Input: RDI = Domain (AF_INET), RSI = Type (SOCK_STREAM), RDX = Protocol (0)
; Output: RAX = Socket FD, or negative on error
_net_socket:
    @save_context
    mov rax, SYS_SOCKET
    syscall
    @restore_context
    ret

; --- [ Bind Socket ] ---
; Input: RDI = Socket FD, RSI = Pointer to sockaddr_in, RDX = Addr length
_net_bind:
    @save_context
    mov rax, SYS_BIND
    syscall
    @restore_context
    ret

; --- [ Listen for Connections ] ---
; Input: RDI = Socket FD, RSI = Backlog
_net_listen:
    @save_context
    mov rax, SYS_LISTEN
    syscall
    @restore_context
    ret

; --- [ Accept Connection ] ---
; Input: RDI = Socket FD, RSI = Pointer to sockaddr_in (output), RDX = Pointer to addr len
_net_accept:
    @save_context
    mov rax, SYS_ACCEPT
    syscall
    @restore_context
    ret

; --- [ Connect to Host ] ---
; Input: RDI = Socket FD, RSI = Pointer to sockaddr_in structure, RDX = Addr length (16)
; Output: RAX = 0 on success, or negative on error
_net_connect:
    @save_context
    mov rax, SYS_CONNECT
    syscall
    @restore_context
    ret

; --- [ Send Data ] ---
; Input: RDI = Socket FD, RSI = Buffer pointer, RDX = Length, RCX = Flags (0)
; Output: RAX = Number of bytes sent, or negative on error
_net_send:
    @save_context
    mov r8, 0           ; dest_addr (NULL for connected sockets)
    mov r9, 0           ; addr_len
    mov r10, rcx        ; flags
    mov rax, SYS_SENDTO
    syscall
    @restore_context
    ret

; --- [ Receive Data ] ---
; Input: RDI = Socket FD, RSI = Buffer pointer, RDX = Length, RCX = Flags (0)
; Output: RAX = Number of bytes received, or negative on error
_net_recv:
    @save_context
    mov r8, 0           ; src_addr (NULL)
    mov r9, 0           ; addr_len
    mov r10, rcx        ; flags
    mov rax, SYS_RECVFROM
    syscall
    @restore_context
    ret

; --- [ Close Socket ] ---
; Input: RDI = Socket FD
_net_close:
    @save_context
    mov rax, SYS_CLOSE
    syscall
    @restore_context
    ret

; --- [ Helper: Host to Network Short (htons) ] ---
; Input: DI = 16-bit port in host order
; Output: AX = 16-bit port in network order (big-endian)
_htons:
    mov ax, di
    xchg al, ah
    ret

; --- [ Helper: ASCII IP to Network Long (aton) ] ---
; Input: RDI = IP String (e.g., "127.0.0.1")
; Output: EAX = IP in network order (dword)
_net_aton:
    @save_context
    xor r8, r8          ; Result accumulator
    xor r9, r9          ; Part accumulator
    mov rcx, 4          ; 4 parts
.loop_parts:
    xor r9, r9
.loop_digits:
    movzx rax, byte [rdi]
    test rax, rax
    jz .done_parts
    cmp al, '.'
    je .next_part
    cmp al, '0'
    jb .next_part
    cmp al, '9'
    ja .next_part
    
    sub al, '0'
    imul r9, 10
    add r9, rax
    inc rdi
    jmp .loop_digits
.next_part:
    shl r8, 8
    or r8, r9
    inc rdi
    loop .loop_parts
    jmp .finish
.done_parts:
    shl r8, 8
    or r8, r9
.finish:
    mov rax, r8
    bswap eax
    @restore_context
    ret
