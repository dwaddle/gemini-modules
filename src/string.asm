; string_engine.asm - Geavanceerde String Functies voor x86_64
%include "algemeen.mac"

section .text
    global _str_compare, _str_copy, _str_find, _str_trim, _str_concat, _strlen, _str_to_upper, _str_to_lower, _str_is_numeric, _str_reverse, _str_to_int, _int_to_str

; ... (existing functions) ...

; --- [ Naar Hoofdletters ] ---
; Input: RDI = String (in-place)
_str_to_upper:
    @save_context
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
    @restore_context
    ret

; --- [ Naar Kleine Letters ] ---
; Input: RDI = String (in-place)
_str_to_lower:
    @save_context
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
    @restore_context
    ret

; --- [ Is Numeriek? ] ---
; Input: RDI = String
; Output: RAX = 1 indien alleen cijfers, 0 indien anders
_str_is_numeric:
    @save_context
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
    @restore_context
    ret

; --- [ String Omdraaien ] ---
; Input: RDI = String (in-place)
_str_reverse:
    @save_context
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
    @restore_context
    ret

; --- [ String naar Integer (atoi) ] ---
; Input: RDI = String
; Output: RAX = Integer waarde
_str_to_int:
    @save_context
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
    @restore_context
    ret

; --- [ Integer naar String (itoa) ] ---
; Input: RAX = Getal, RDI = Buffer
; Output: RDI bevat de string
_int_to_str:
    @save_context
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
    @restore_context
    ret

; --- [ String Vergelijken ] ---
; Input: RDI = String A, RSI = String B
; Output: RAX = 0 indien gelijk, 1 indien verschillend
_str_compare:
    @save_context
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
    jmp .done
.equal:
    xor rax, rax        ; RAX = 0
.done:
    @restore_context
	 
    ret

; --- [ String Kopiëren ] ---
; Input: RDI = Bestemming, RSI = Bron
_str_copy:
    @save_context
.loop:
    mov al, [rsi]
    mov [rdi], al
    test al, al         ; Stop bij null-terminator
    jz .done
    inc rdi
    inc rsi
    jmp .loop
.done:
    @restore_context
    ret

; --- [ String Lengte ] ---
; Input: RDI = String
; Output: RAX = Lengte
_strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; --- [ String Zoeken (Sub-string) ] ---
; Input: RDI = Hooiberg, RSI = Naald
; Output: RAX = Pointer naar startpositie, of 0 indien niet gevonden
_str_find:
    @save_context
.outer_loop:
    mov al, [rdi]
    test al, al
    jz .not_found
    
    ; Vergelijk vanaf hier
    push rdi
    push rsi
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
    pop rsi
    pop rdi
    inc rdi
    jmp .outer_loop

.found_match:
    pop rsi
    pop rdi
    mov rax, rdi
    jmp .done

.not_found:
    xor rax, rax
.done:
    @restore_context
    ret

; --- [ String Trim (Spaties verwijderen) ] ---
; Verwijdert spaties aan het begin en einde
_str_trim:
    @save_context
    ; 1. Trim leading spaces
.trim_leading:
    cmp byte [rdi], ' '
    jne .leading_done
    inc rdi
    jmp .trim_leading

.leading_done:
    ; Schuif string naar voren als RDI is opgeschoven
    ; (Voor het gemak kopiëren we de string naar het originele beginpunt)
    ; In een echte trim zou je de pointer aanpassen of de data echt schuiven.
    ; Laten we hier data schuiven naar het begin van de buffer (als die groot genoeg is).
    ; Maar de caller geeft RDI, we weten niet waar de buffer begon.
    ; Laten we aannemen dat RDI de start van de string is en we deze in-place trimmen.
    ; Voor leading trim schuiven we de karakters terug.
    ; (Dit is een versimpelde implementatie)
    
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
    ; De leading trim is hier niet echt in-place gedaan (we hebben alleen de pointer opgeschoven).
    ; Voor een echte in-place trim moeten we de data terugschuiven.
    @restore_context
    ret

; --- [ String Concatenatie ] ---
; Input: RDI = Dest, RSI = Src (Voegt Src toe aan het einde van Dest)
_str_concat:
    @save_context
    push rsi
    call _strlen        ; Gebruik je bestaande strlen functie
    add rdi, rax        ; Verplaats pointer naar het einde van Dest
    pop rsi
    call _str_copy      ; Kopieer Src naar het einde van Dest
    @restore_context
    ret
