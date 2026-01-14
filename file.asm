; ---------------------------------------------------------
; FILE MODULE - Bestandsafhandeling
; ---------------------------------------------------------
section .text
global OpenFileReadOnly
global CloseFile

; Input: RDI = Bestandsnaam (string)
; Output: RAX = File Descriptor (of negatief bij fout)
OpenFileReadOnly:
    mov rax, 2          ; syscall: sys_open
    mov rsi, 0          ; O_RDONLY (alleen lezen)
    mov rdx, 0          ; Mode (niet nodig bij lezen)
    syscall
    ret

; Input: RDI = File Descriptor
CloseFile:
    mov rax, 3          ; syscall: sys_close
    syscall
    ret
