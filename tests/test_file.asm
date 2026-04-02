; test_file.asm - Test for File Module
%include "algemeen.mac"
%include "file_constants.inc"

section .data
    filename db "test.tmp", 0
    new_filename db "test_renamed.tmp", 0
    content db "Hello File I/O!", 0
    content_len equ $ - content
    
    msg_open db "Test: File Open/Create", 0
    msg_write db "Test: File Write", 0
    msg_size db "Test: File Size", 0
    msg_exists db "Test: File Exists", 0
    msg_seek db "Test: File Seek", 0
    msg_rename db "Test: File Rename", 0
    msg_read db "Test: File Read", 0
    msg_close db "Test: File Close", 0
    msg_delete db "Test: File Delete", 0
    msg_ok db " [OK]", 10, 0
    msg_fail db " [FAIL]", 10, 0

section .bss
    read_buffer resb 64
    fd resq 1

section .text
    global _start
    extern _file_open, _file_close, _file_read, _file_write, _file_size
    extern _file_exists, _file_delete, _file_rename, _file_seek
    extern PrintString

_start:
    ; 1. Open/Create
    mov rdi, msg_open
    call PrintString
    mov rdi, filename
    mov rsi, O_CREAT | O_RDWR | O_TRUNC
    mov rdx, RW_USER
    call _file_open
    test rax, rax
    js .fail
    mov [fd], rax
    call .pass

    ; 2. Write
    mov rdi, msg_write
    call PrintString
    mov rdi, [fd]
    mov rsi, content
    mov rdx, content_len
    call _file_write
    cmp rax, content_len
    jne .fail
    call .pass

    ; 3. Exists
    mov rdi, msg_exists
    call PrintString
    mov rdi, filename
    call _file_exists
    test rax, rax
    jnz .fail
    call .pass

    ; 4. Size
    mov rdi, msg_size
    call PrintString
    mov rdi, filename
    call _file_size
    cmp rax, content_len
    jne .fail
    call .pass

    ; 5. Seek
    mov rdi, msg_seek
    call PrintString
    mov rdi, [fd]
    mov rsi, 0
    mov rdx, SEEK_SET
    call _file_seek
    test rax, rax
    jnz .fail
    call .pass

    ; 6. Read
    mov rdi, msg_read
    call PrintString
    mov rdi, [fd]
    mov rsi, read_buffer
    mov rdx, content_len
    call _file_read
    cmp rax, content_len
    jne .fail
    call .pass

    ; 7. Rename
    mov rdi, msg_rename
    call PrintString
    mov rdi, [fd]
    call _file_close
    mov rdi, filename
    mov rsi, new_filename
    call _file_rename
    test rax, rax
    jnz .fail
    call .pass

    ; 8. Delete
    mov rdi, msg_delete
    call PrintString
    mov rdi, new_filename
    call _file_delete
    test rax, rax
    jnz .fail
    call .pass

    @exit 0

.pass:
    mov rdi, msg_ok
    call PrintString
    ret

.fail:
    mov rdi, msg_fail
    call PrintString
    @exit 1
