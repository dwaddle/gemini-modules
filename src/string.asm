; string_engine.asm - Geavanceerde String Functies voor x86_64
%include "algemeen.mac"

section .text
    global _str_compare, _str_copy, _str_find, _str_trim, _str_concat, _strlen, _str_to_upper, _str_to_lower, _str_is_numeric, _str_reverse, _str_to_int, _int_to_str

; ... (existing functions) ...

; --- [ Naar Hoofdletters ] ---
; Input: RDI = String (in-place)
_str_to_upper:
    ; Caller-saved registers only, no stack needed
.loop:
    mov al, [rdi]
    test al, al
    jz .done
    cmp al, 'a'
    jb .next
    cmp al, 'z'
    ja .next
    sub al, 32
    mov [rdi], al
.next:
    inc rdi
    jmp .loop
.done:
    ret

; --- [ Naar Kleine Letters ] ---
; Input: RDI = String (in-place)
_str_to_lower:
.loop:
    mov al, [rdi]
    test al, al
    jz .done
    cmp al, 'A'
    jb .next
    cmp al, 'Z'
    ja .next
    add al, 32
    mov [rdi], al
.next:
    inc rdi
    jmp .loop
.done:
    ret

; --- [ Is Numeriek? ] ---
; Input: RDI = String
; Output: RAX = 1 indien alleen cijfers, 0 indien anders
_str_is_numeric:
    xor rax, rax
.loop:
    mov cl, [rdi]
    test cl, cl
    jz .is_num
    cmp cl, '0'
    jb .not_num
    cmp cl, '9'
    ja .not_num
    inc rdi
    jmp .loop
.is_num:
    mov rax, 1
    jmp .done
.not_num:
    xor rax, rax
.done:
    ret

; --- [ String Omdraaien ] ---
; Input: RDI = String (in-place)
_str_reverse:
    push rbx            ; RBX is callee-saved
    call _strlen
    test rax, rax
    jz .done
    
    mov rsi, rdi        ; RSI = start
    add rdi, rax
    dec rdi             ; RDI = eind
.loop:
    cmp rsi, rdi
    jae .done
    mov al, [rsi]
    mov bl, [rdi]
    mov [rsi], bl
    mov [rdi], al
    inc rsi
    dec rdi
    jmp .loop
.done:
    pop rbx
    ret

; --- [ String naar Integer (atoi) ] ---
; Input: RDI = String
; Output: RAX = Integer waarde
_str_to_int:
    xor rax, rax        ; Resultaat
    xor rcx, rcx        ; Tijdelijk karakter
.loop:
    movzx rcx, byte [rdi]
    test rcx, rcx
    jz .done
    cmp rcx, '0'
    jb .done
    cmp rcx, '9'
    ja .done
    
    sub rcx, '0'
    imul rax, 10
    add rax, rcx
    inc rdi
    jmp .loop
.done:
    ret

; --- [ Integer naar String (itoa) ] ---
; Input: RAX = Getal, RDI = Buffer
; Output: RDI bevat de string
_int_to_str:
    push rbx
    mov rsi, rdi        ; Bewaar start van buffer
    mov rbx, 10         ; Deler
    xor rcx, rcx        ; Teller voor karakters
.div_loop:
    xor rdx, rdx
    div rbx             ; RAX = quotient, RDX = remainder
    add dl, '0'
    push rdx            ; Sla karakter op de stack op (omgekeerde volgorde)
    inc rcx
    test rax, rax
    jnz .div_loop
.store_loop:
    pop rdx
    mov [rdi], dl
    inc rdi
    loop .store_loop
    mov byte [rdi], 0   ; Null-terminator
    pop rbx
    ret

; --- [ String Vergelijken ] ---
; Input: RDI = String A, RSI = String B
; Output: RAX = 0 indien gelijk, 1 indien verschillend
_str_compare:
.loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl          ; Vergelijk karakters
    jne .different
    test al, al         ; Einde van string?
    jz .equal
    inc rdi
    inc rsi
    jmp .loop
.different:
    mov rax, 1
    ret
.equal:
    xor rax, rax        ; RAX = 0
    ret

; --- [ String Kopiëren ] ---
; Input: RDI = Bestemming, RSI = Bron
_str_copy:
.loop:
    mov al, [rsi]
    mov [rdi], al
    test al, al         ; Stop bij null-terminator
    jz .done
    inc rdi
    inc rsi
    jmp .loop
.done:
    ret

; --- [ String Lengte (SIMD Optimized) ] ---
; Input: RDI = String
; Output: RAX = Lengte
_strlen:
    mov rax, rdi
    pxor xmm0, xmm0     ; Zoek naar null-terminator
.loop:
    movdqu xmm1, [rax]  ; Laad 16 bytes
    pcmpeqb xmm1, xmm0  ; Vergelijk bytes met 0
    pmovmskb edx, xmm1  ; Maak bitmasker
    test edx, edx       ; Null gevonden?
    jnz .found
    add rax, 16
    jmp .loop
.found:
    bsf edx, edx        ; Eerste '1' bit
    add rax, rdx
    sub rax, rdi        ; Lengte
    ret


; --- [ String Zoeken (Sub-string) ] ---
; Input: RDI = Hooiberg, RSI = Naald
; Output: RAX = Pointer naar startpositie, of 0 indien niet gevonden
_str_find:
    push rbx
    push r12
    push r13
    mov r12, rdi        ; Hooiberg
    mov r13, rsi        ; Naald

.outer_loop:
    mov al, [r12]
    test al, al
    jz .not_found
    
    ; Vergelijk vanaf hier
    mov rdi, r12
    mov rsi, r13
.inner_loop:
    mov al, [rdi]
    mov bl, [rsi]
    test bl, bl         ; Naald op? Succes!
    jz .found_match
    cmp al, bl
    jne .no_match
    test al, al
    jz .no_match
    inc rdi
    inc rsi
    jmp .inner_loop

.no_match:
    inc r12
    jmp .outer_loop

.found_match:
    mov rax, r12
    jmp .done

.not_found:
    xor rax, rax
.done:
    pop r13
    pop r12
    pop rbx
    ret

; --- [ String Trim (Spaties verwijderen) ] ---
; Verwijdert spaties aan het begin en einde
_str_trim:
    ; 1. Trim leading spaces
.trim_leading:
    cmp byte [rdi], ' '
    jne .leading_done
    inc rdi
    jmp .trim_leading

.leading_done:
    ; 2. Trim trailing spaces
    mov rsi, rdi
.find_end:
    cmp byte [rsi], 0
    je .check_trailing
    inc rsi
    jmp .find_end
.check_trailing:
    dec rsi
.trim_trailing:
    cmp rsi, rdi
    jb .done
    cmp byte [rsi], ' '
    jne .set_null
    dec rsi
    jmp .trim_trailing
.set_null:
    mov byte [rsi + 1], 0
.done:
    ret

; --- [ String Concatenatie ] ---
; Input: RDI = Dest, RSI = Src (Voegt Src toe aan het einde van Dest)
_str_concat:
    push rdi
    push rsi
    call _strlen        ; RAX = lengte van Dest
    pop rsi
    pop rdi
    push rdi            ; Bewaar originele Dest voor return? Nee, concat past in-place aan.
    add rdi, rax        ; Verplaats pointer naar het einde van Dest
    call _str_copy      ; Kopieer Src naar het einde van Dest
    pop rdi
    ret
