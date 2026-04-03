; memory.asm - Geheugenbeheer en Manipulatie voor x86_64
%include "syscalls.inc"
%include "algemeen.mac"

section .data
    heap_start    dq 0
    heap_current  dq 0

section .text
    global _mem_alloc, _mem_free, _mem_copy, _mem_set, _mem_compare

; --- [ Geheugen Alloceren (malloc) ] ---
; Input: RDI = Aantal bytes
; Output: RAX = Adres van gealloceerd blok, of 0 bij fout
_mem_alloc:
    @save_context
    mov rbx, rdi            ; Bewaar gevraagde grootte
    
    ; Initialiseer heap indien nodig
    mov rax, [heap_start]
    test rax, rax
    jnz .allocate
    
    ; Haal huidige break op
    mov rax, SYS_BRK
    xor rdi, rdi
    syscall
    mov [heap_start], rax
    mov [heap_current], rax

.allocate:
    mov rdi, [heap_current]
    add rdi, rbx            ; Nieuwe break positie
    mov rax, SYS_BRK
    syscall
    
    ; Check of het gelukt is (RAX is nieuwe break)
    cmp rax, [heap_current]
    jbe .error
    
    mov rsi, [heap_current] ; Oude break is het begin van ons blok
    mov [heap_current], rax ; Update current break
    mov rax, rsi
    
    @restore_context
    ret
.error:
    xor rax, rax
    @restore_context
    ret

; --- [ Geheugen Vrijgeven (free) ] ---
; Opmerking: In deze simpele brk-implementatie kunnen we alleen de 
; laatste allocatie echt teruggeven aan het OS. Voor nu een placeholder.
_mem_free:
    ret

; --- [ Geheugen Kopiëren (memcpy) ] ---
; Input: RDI = Dest, RSI = Src, RDX = Count
_mem_copy:
    @save_context
    mov rcx, rdx
    rep movsb               ; Kopieer RCX bytes van [RSI] naar [RDI]
    @restore_context
    ret

; --- [ Geheugen Vullen (memset) ] ---
; Input: RDI = Dest, RSI = Waarde (byte), RDX = Count
_mem_set:
    @save_context
    mov rax, rsi
    mov rcx, rdx
    rep stosb               ; Vul RCX bytes op [RDI] met waarde in AL
    @restore_context
    ret

; --- [ Geheugen Vergelijken (memcmp) ] ---
; Input: RDI = Buf1, RSI = Buf2, RDX = Count
; Output: RAX = 0 indien gelijk, anders verschil
_mem_compare:
    @save_context
    mov rcx, rdx
    repe cmpsb              ; Vergelijk tot verschil of RCX=0
    je .equal
    movzx rax, byte [rdi-1]
    movzx rbx, byte [rsi-1]
    sub rax, rbx
    jmp .done
.equal:
    xor rax, rax
.done:
    @restore_context
    ret
