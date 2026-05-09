; asm_help.asm - Professional ASM Documentation Search Tool
%include "algemeen.mac"
%include "system.mac"
%include "file.mac"
%include "memory.mac"
%include "string.mac"

section .data
    manual_path     db "MANUAL.md", 0
    manual_path_up  db "../MANUAL.md", 0
    
    msg_usage       db "Professional ASM Help Tool", 10
                    db "---------------------------", 10
                    db "Gebruik:", 10
                    db "  asm-help <functie>    Toon details van een specifieke functie", 10
                    db "  asm-help              Toon een lijst van alle functies", 10
                    db "  asm-help --help       Toon deze help informatie", 10, 10
                    db "Opmerking: Deze tool is volledig geschreven in Professional ASM,", 10
                    db "gebruikmakend van de eigen System, File, Memory en String modules.", 10, 0
    
    msg_error       db "Fout: Kan MANUAL.md niet openen.", 10, 0
    msg_notfound    db "Fout: Functie niet gevonden in de handleiding.", 10, 0
    msg_searching   db "Zoeken naar: ", 0
    msg_listing     db "Beschikbare functies in Professional ASM:", 10, 10, 0
    
    header_sep      db "### ", 0
    flag_help       db "--help", 0
    flag_help_s     db "-h", 0

section .bss
    manual_buf  resq 1
    manual_size resq 1
    query_ptr   resq 1

section .text
    global _start
    extern PrintString, PrintNewline, _strlen, _str_find, _str_compare, _file_open, _file_size, _file_read, _file_close, _mem_alloc

_start:
    ; 1. Save stack pointer for argc/argv
    mov r12, rsp
    @get_argc r12
    mov rbx, rax        ; RBX = argc

    ; 2. Check for --help or -h
    cmp rbx, 2
    jne .check_mode
    
    @get_argv r12, 1
    mov rdi, rax
    mov rsi, flag_help
    call _str_compare
    test rax, rax
    jz .show_usage
    
    @get_argv r12, 1
    mov rdi, rax
    mov rsi, flag_help_s
    call _str_compare
    test rax, rax
    jz .show_usage

.check_mode:
    ; 3. Load Manual into memory
    call _load_manual
    test rax, rax
    jz .open_error
    mov r15, rax        ; R15 = Manual Buffer

    cmp rbx, 2
    jl .list_all

    ; --- Search Mode ---
    @get_argv r12, 1
    mov [query_ptr], rax
    
    mov rdi, msg_searching
    call PrintString
    mov rdi, [query_ptr]
    call PrintString
    call PrintNewline
    call PrintNewline

    mov rdi, r15
    mov rsi, [query_ptr]
    call _str_find
    test rax, rax
    jz .not_found
    
    mov r12, rax
.find_start_hdr:
    cmp r12, r15
    jbe .print_block
    cmp byte [r12], '#'
    jne .prev_block
    cmp byte [r12 + 1], '#'
    jne .prev_block
    cmp byte [r12 + 2], '#'
    je .print_block
.prev_block:
    dec r12
    jmp .find_start_hdr

.print_block:
    mov rdi, r12
    add rdi, 4
.find_end_block:
    movzx rax, byte [rdi]
    test al, al
    jz .do_print_block
    cmp al, '#'
    jne .next_end_block
    cmp byte [rdi+1], '#'
    jne .next_end_block
    cmp byte [rdi+2], '#'
    je .do_print_block
.next_end_block:
    inc rdi
    jmp .find_end_block
.do_print_block:
    mov byte [rdi], 0
    mov rdi, r12
    call PrintString
    call PrintNewline
    @exit 0

    ; --- List Mode ---
.list_all:
    mov rdi, msg_listing
    call PrintString
    
    mov r12, r15        ; Current pointer
.list_loop:
    mov rdi, r12
    mov rsi, header_sep
    call _str_find
    test rax, rax
    jz .list_done
    
    mov r12, rax        ; Gevonden header
    mov rdi, r12
    add rdi, 4          ; Skip "### "
.find_line_end:
    cmp byte [rdi], 10
    je .print_line
    cmp byte [rdi], 0
    je .print_line
    inc rdi
    jmp .find_line_end
    
.print_line:
    mov r13, [rdi]      ; Save char
    mov byte [rdi], 0
    mov rdi, r12
    call PrintString
    call PrintNewline
    mov rdi, r12        ; r12 was start of header
    add rdi, 4
.restore_loop:          ; Find end again to restore
    cmp byte [rdi], 0
    je .do_restore
    inc rdi
    jmp .restore_loop
.do_restore:
    mov [rdi], r13b     ; Restore char
    
    inc rdi
    mov r12, rdi
    jmp .list_loop

.list_done:
    @exit 0

.show_usage:
    mov rdi, msg_usage
    call PrintString
    @exit 0

.open_error:
    mov rdi, msg_error
    call PrintString
    @exit 1

.not_found:
    mov rdi, msg_notfound
    call PrintString
    @exit 1

; --- Helper: Load Manual ---
_load_manual:
    push r12
    push r13
    push r14
    push r15
    
    ; Try current dir
    mov rdi, manual_path
    mov rsi, 0
    call _file_open
    test rax, rax
    jns .open_ok
    
    ; Try parent dir
    mov rdi, manual_path_up
    mov rsi, 0
    call _file_open
    test rax, rax
    js .load_fail

.open_ok:
    mov r13, rax        ; FD
    
    mov rdi, r13
    mov rsi, 0
    mov rdx, 2          ; SEEK_END
    extern _file_seek
    call _file_seek
    mov r14, rax
    
    mov rdi, r13
    mov rsi, 0
    mov rdx, 0          ; SEEK_SET
    call _file_seek
    
    mov rdi, r14
    inc rdi
    call _mem_alloc
    test rax, rax
    jz .load_fail
    mov r15, rax
    
    mov rdi, r13
    mov rsi, r15
    mov rdx, r14
    call _file_read
    mov byte [r15 + r14], 0
    
    mov rdi, r13
    call _file_close
    mov rax, r15
    pop r15
    pop r14
    pop r13
    pop r12
    ret
.load_fail:
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    ret
