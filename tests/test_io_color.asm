; test_io_color.asm - Test for PrintColorString
%include "algemeen.mac"

section .data
    test_str db "Standaard |RROOD |GGROEN |YGEEL |Wwit || literal pipe |yweer normaal", 10, 0

section .text
    global _start
    extern PrintColorString, PrintNewline

_start:
    mov rdi, test_str
    call PrintColorString
    
    @exit 0
