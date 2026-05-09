; test_io_color.asm - Test for Expanded PrintColorString
%include "algemeen.mac"

section .data
    msg_intro db "Professional ASM Extended Color Test:", 10, 0
    test_str  db "Basis: |RRed |GGreen |BYellow |BBlue |!|n"
              db "Bright: |rBright Red |gBright Green |yBright Yellow |bBright Blue |!|n"
              db "256 Palette: |[208]Orange |[13]Purple-ish |[46]Lime |[21]Deep Blue |!|n"
              db "Literal: || pipe symbol || |n"
              db "Done.|n", 0

section .text
    global _start
    extern PrintColorString, PrintNewline

_start:
    ; Intro
    mov rdi, msg_intro
    call PrintColorString
    
    ; Test string
    mov rdi, test_str
    call PrintColorString
    
    @exit 0
