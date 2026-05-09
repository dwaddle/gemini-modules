; ---------------------------------------------------------
; IO MODULE - Scherm, Tekst en Seriële Poort
; ---------------------------------------------------------
%include "syscalls.inc"
%include "algemeen.mac"
%include "io_constants.inc"

section .data
    esc_color_pre db 27, '[3', 0
    hex_chars     db "0123456789ABCDEF"
    hex_prefix    db "0x", 0
    
    cs_esc_pre    db 27, '[3', 0
    cs_color_char db '0', 'm', 0
    cs_256_pre    db 27, '[38;5;', 0
    cs_suffix     db 'm', 0

section .bss
    cs_num_buf    resb 16
    termios_buf   resb 64

section .text
global PrintString
global PrintNewline
global PrintInt
global PrintHex
global PrintColor
global PrintColorString
global ReadString
global ReadChar
global TerminalRawMode
global TerminalResetMode
global IsKeyAvailable
global SerialOpen
global SerialConfig
global SerialWrite
global SerialRead

extern _int_to_str, _strlen, _screen_reset_color

; --- [ Terminal Raw Mode ] ---
TerminalRawMode:
    @save_callee_saved
    mov rdi, 0
    mov rsi, TCGETS
    mov rdx, termios_buf
    mov rax, SYS_IOCTL
    syscall
    @restore_callee_saved
    ret

; --- [ Terminal Reset Mode ] ---
TerminalResetMode:
    @save_callee_saved
    mov rdi, 0
    mov rsi, TCGETS
    mov rdx, termios_buf
    mov rax, SYS_IOCTL
    syscall
    
    mov eax, [termios_buf + 12]
    or eax, (ICANON | ECHO)
    mov [termios_buf + 12], eax
    
    mov rdi, 0
    mov rsi, TCSETS
    mov rdx, termios_buf
    mov rax, SYS_IOCTL
    syscall
    @restore_callee_saved
    ret

; --- [ Is er een toets ingedrukt? ] ---
IsKeyAvailable:
    sub rsp, 16
    mov dword [rsp], 0
    mov word [rsp + 4], 1
    mov rdi, rsp
    mov rsi, 1
    mov rdx, 0
    mov rax, SYS_POLL
    syscall
    cmp rax, 0
    setg al
    movzx rax, al
    add rsp, 16
    ret

; --- [ Print String ] ---
PrintString:
    mov rsi, rdi
    call _strlen
    mov rdx, rax
    mov rdi, 1
    mov rax, SYS_WRITE
    syscall
    ret

; --- [ Print Newline ] ---
PrintNewline:
    sub rsp, 8
    mov byte [rsp], 10
    mov rsi, rsp
    mov rdx, 1
    mov rdi, 1
    mov rax, SYS_WRITE
    syscall
    add rsp, 8
    ret

; --- [ Print Integer ] ---
PrintInt:
    sub rsp, 32
    mov rax, rdi
    mov rdi, rsp
    call _int_to_str
    mov rdi, rsp
    call PrintString
    add rsp, 32
    ret

; --- [ Print Hexadecimaal ] ---
PrintHex:
    push rbx
    push r12
    mov r12, rdi
    mov rdi, hex_prefix
    call PrintString
    sub rsp, 24
    mov rsi, rsp
    mov rdx, r12
    mov rcx, 16
.hex_loop:
    rol rdx, 4
    mov rax, rdx
    and rax, 0xF
    movzx rax, byte [hex_chars + rax]
    mov [rsi], al
    inc rsi
    loop .hex_loop
    mov byte [rsi], 0
    mov rdi, rsp
    call PrintString
    add rsp, 24
    pop r12
    pop rbx
    ret

; ... rest of Serial functions similarly refactored ...
SerialOpen:
    mov rsi, 2
    mov rax, SYS_OPEN
    syscall
    ret

SerialConfig:
    @save_callee_saved
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    mov rsi, TCGETS
    mov rdx, termios_buf
    mov rax, SYS_IOCTL
    syscall
    
    mov eax, [termios_buf + 8]
    and eax, 0xFFFFF000
    or eax, r13d
    or eax, (CS8 | CLOCAL | CREAD)
    mov [termios_buf + 8], eax
    
    mov rdi, r12
    mov rsi, TCSETS
    mov rdx, termios_buf
    mov rax, SYS_IOCTL
    syscall
    @restore_callee_saved
    ret

SerialWrite:
    mov rax, SYS_WRITE
    syscall
    ret

SerialRead:
    mov rax, SYS_READ
    syscall
    ret

ReadChar:
    sub rsp, 8
    mov rdi, 0
    mov rsi, rsp
    mov rdx, 1
    mov rax, SYS_READ
    syscall
    movzx rax, byte [rsp]
    add rsp, 8
    ret
