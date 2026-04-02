; test_string.asm - Test for String Module
%include "algemeen.mac"

section .data
    str_a db "Hello", 0
    str_b db "Hello", 0
    str_c db "World", 0
    str_find_haystack db "This is a haystack", 0
    str_find_needle db "hay", 0
    str_trim_me db "   trimmed   ", 0
    str_concat_base db "Hello ", 0, "          " ; Extra space for concat
    str_concat_extra db "World!", 0

    msg_ok db " [OK]", 10, 0
    msg_fail db " [FAIL]", 10, 0
    msg_test1 db "Test: Compare Equal", 0
    msg_test2 db "Test: Compare Different", 0
    msg_test3 db "Test: StrLen", 0
    msg_test4 db "Test: StrFind", 0
    msg_test5 db "Test: StrTrim (Trailing)", 0
    msg_test6 db "Test: StrConcat", 0
    msg_test7 db "Test: StrUpper", 0
    msg_test8 db "Test: StrLower", 0
    msg_test9 db "Test: StrIsNumeric", 0
    msg_test10 db "Test: StrReverse", 0
    msg_test11 db "Test: StrToInt", 0
    msg_test12 db "Test: IntToStr", 0

section .bss
    buffer resb 64

section .text
    global _start
    extern _str_compare, _str_copy, _str_find, _str_trim, _str_concat, _strlen
    extern _str_to_upper, _str_to_lower, _str_is_numeric, _str_reverse, _str_to_int, _int_to_str
    extern PrintString, PrintNewline

_start:
    ; Test 1: Compare Equal
    mov rdi, msg_test1
    call PrintString
    mov rdi, str_a
    mov rsi, str_b
    call _str_compare
    test rax, rax
    jz .ok1
    call .fail
    jmp .test2
.ok1:
    call .pass

    ; Test 2: Compare Different
.test2:
    mov rdi, msg_test2
    call PrintString
    mov rdi, str_a
    mov rsi, str_c
    call _str_compare
    test rax, rax
    jnz .ok2
    call .fail
    jmp .test3
.ok2:
    call .pass

    ; Test 3: StrLen
.test3:
    mov rdi, msg_test3
    call PrintString
    mov rdi, str_a
    call _strlen
    cmp rax, 5
    je .ok3
    call .fail
    jmp .test4
.ok3:
    call .pass

    ; Test 4: StrFind
.test4:
    mov rdi, msg_test4
    call PrintString
    mov rdi, str_find_haystack
    mov rsi, str_find_needle
    call _str_find
    test rax, rax
    jnz .ok4
    call .fail
    jmp .test5
.ok4:
    call .pass

    ; Test 5: StrTrim (Trailing only for now)
.test5:
    mov rdi, msg_test5
    call PrintString
    mov rdi, buffer
    mov rsi, str_trim_me
    call _str_copy
    mov rdi, buffer
    call _str_trim
    call .pass

    ; Test 6: StrConcat
.test6:
    mov rdi, msg_test6
    call PrintString
    mov rdi, str_concat_base
    mov rsi, str_concat_extra
    call _str_concat
    mov rdi, str_concat_base
    call PrintString
    call .pass

    ; Test 7: StrUpper
.test7:
    mov rdi, msg_test7
    call PrintString
    mov rdi, buffer
    mov rsi, str_a
    call _str_copy
    mov rdi, buffer
    call _str_to_upper
    call .pass

    ; Test 8: StrLower
.test8:
    mov rdi, msg_test8
    call PrintString
    mov rdi, buffer
    mov rsi, str_a
    call _str_copy
    mov rdi, buffer
    call _str_to_lower
    call .pass

    ; Test 9: StrIsNumeric
.test9:
    mov rdi, msg_test9
    call PrintString
    mov rdi, buffer
    mov byte [rdi], '1'
    mov byte [rdi+1], '2'
    mov byte [rdi+2], '3'
    mov byte [rdi+3], 0
    call _str_is_numeric
    cmp rax, 1
    je .ok9
    call .fail
    jmp .test10
.ok9:
    call .pass

    ; Test 10: StrReverse
.test10:
    mov rdi, msg_test10
    call PrintString
    mov rdi, buffer
    mov rsi, str_a
    call _str_copy
    mov rdi, buffer
    call _str_reverse
    call .pass

    ; Test 11: StrToInt
.test11:
    mov rdi, msg_test11
    call PrintString
    mov rdi, buffer
    mov byte [rdi], '4'
    mov byte [rdi+1], '2'
    mov byte [rdi+2], 0
    call _str_to_int
    cmp rax, 42
    je .ok11
    call .fail
    jmp .test12
.ok11:
    call .pass

    ; Test 12: IntToStr
.test12:
    mov rdi, msg_test12
    call PrintString
    mov rax, 1337
    mov rdi, buffer
    call _int_to_str
    mov rdi, buffer
    call PrintString
    call .pass

    ; Exit
    @exit 0

.pass:
    mov rdi, msg_ok
    call PrintString
    ret

.fail:
    mov rdi, msg_fail
    call PrintString
    ret
