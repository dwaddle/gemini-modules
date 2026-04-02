; file_engine.asm - Geavanceerde File I/O voor x86_64
%include "syscalls.inc"
%include "algemeen.mac"

section .text
    global _file_open, _file_close, _file_read, _file_write, _file_size, _file_exists, _file_delete, _file_rename, _file_seek

; --- [ Bestaat Bestand? ] ---
; Input: RDI = Filename
; Output: RAX = 0 indien bestaat, anders negatief
_file_exists:
    mov rax, SYS_ACCESS
    mov rsi, 0              ; F_OK
    syscall
    ret

; --- [ Verwijder Bestand ] ---
; Input: RDI = Filename
; Output: RAX = 0 bij succes, anders negatief
_file_delete:
    mov rax, SYS_UNLINK
    syscall
    ret

; --- [ Hernoem Bestand ] ---
; Input: RDI = Oude naam, RSI = Nieuwe naam
; Output: RAX = 0 bij succes, anders negatief
_file_rename:
    mov rax, SYS_RENAME
    syscall
    ret

; --- [ Verplaats Bestandscursor (Seek) ] ---
; Input: RDI = FD, RSI = Offset, RDX = Whence (SEEK_SET, SEEK_CUR, SEEK_END)
; Output: RAX = Nieuwe positie vanaf begin, of negatief bij fout
_file_seek:
    mov rax, SYS_LSEEK
    syscall
    ret

; --- [ Open Bestand ] ---
; Input: RDI = Filename, RSI = Flags, RDX = Mode
; Output: RAX = FD, of negatief bij fout
_file_open:
    mov rax, SYS_OPEN
    syscall
    ret

; --- [ Sluit Bestand ] ---
; Input: RDI = FD
_file_close:
    mov rax, SYS_CLOSE
    syscall
    ret

; --- [ Bepaal Bestandsgrootte ] ---
; Input: RDI = Filename
; Output: RAX = Grootte in bytes
_file_size:
    @save_context
    sub rsp, 144            ; Ruimte voor 'struct stat' (144 bytes op x64)
    mov rsi, rsp            ; Stat buffer
    mov rax, SYS_STAT
    syscall
    test rax, rax
    js .error
    mov rax, [rsp + 48]     ; st_size bevindt zich op offset 48
    add rsp, 144
    @restore_context
    ret
.error:
    add rsp, 144
    @restore_context
    mov rax, -1
    ret

; --- [ Lees Bestand ] ---
; Input: RDI = FD, RSI = Buffer, RDX = Aantal bytes
_file_read:
    mov rax, SYS_READ
    syscall
    ret

; --- [ Schrijf naar Bestand ] ---
; Input: RDI = FD, RSI = Buffer, RDX = Aantal bytes
_file_write:
    mov rax, SYS_WRITE
    syscall
    ret
