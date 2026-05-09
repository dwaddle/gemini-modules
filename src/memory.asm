; memory.asm - Advanced Memory Management for x86_64
%include "syscalls.inc"
%include "algemeen.mac"

; --- Memory Block Header Definition ---
MEM_BLOCK_HEADER_SIZE equ 32
MEM_BLOCK_NEXT        equ 0
MEM_BLOCK_PREV        equ 8
MEM_BLOCK_SIZE        equ 16
MEM_BLOCK_FLAGS       equ 24

; Flags
MEM_FLAG_FREE         equ 1
MEM_FLAG_MMAP         equ 2

; SLAB Constants
SLAB_NODE_SIZE        equ 32    ; 16 bytes data + overhead
SLAB_BLOCK_SIZE       equ 4096  ; 1 page

section .data
    heap_start    dq 0
    heap_current  dq 0
    free_list_head dq 0
    
    ; Slab for small objects (Linked List Nodes)
    slab_node_head dq 0

section .text
    global _mem_alloc, _mem_free, _mem_copy, _mem_set, _mem_compare
    global _slab_alloc_node, _slab_free_node

; --- [ Geheugen Alloceren (malloc style) ] ---
; Gebruikt mmap voor stabiliteit en minder fragmentatie
_mem_alloc:
    @save_callee_saved
    mov r12, rdi        ; R12 = requested size
    
    ; Voeg header toe
    add rdi, MEM_BLOCK_HEADER_SIZE
    
    ; Voor grote allocaties (> 4KB), gebruik mmap
    cmp r12, 4032
    ja .use_mmap
    
    ; Standaard heap (brk) voor kleine blokken
    call _internal_brk_alloc
    jmp .done

.use_mmap:
    ; SYS_MMAP: rdi=addr, rsi=len, rdx=prot, r10=flags, r8=fd, r9=off
    mov rsi, rdi        ; len
    xor rdi, rdi        ; addr=0
    mov rdx, 3          ; PROT_READ | PROT_WRITE
    mov r10, 34         ; MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1          ; fd
    xor r9, r9          ; offset
    mov rax, 9          ; SYS_MMAP
    syscall
    
    test rax, rax
    js .error
    
    ; Setup header
    mov qword [rax + MEM_BLOCK_SIZE], r12
    mov qword [rax + MEM_BLOCK_FLAGS], MEM_FLAG_MMAP
    add rax, MEM_BLOCK_HEADER_SIZE
    jmp .done

.error:
    xor rax, rax
.done:
    @restore_callee_saved
    ret

; --- [ Geheugen Vrijgeven (free style) ] ---
_mem_free:
    test rdi, rdi
    jz .done
    
    sub rdi, MEM_BLOCK_HEADER_SIZE
    mov rsi, [rdi + MEM_BLOCK_FLAGS]
    
    test rsi, MEM_FLAG_MMAP
    jnz .free_mmap
    
    ; Markeer als vrij in heap (coalescing weggelaten voor eenvoud hier)
    or qword [rdi + MEM_BLOCK_FLAGS], MEM_FLAG_FREE
    ret

.free_mmap:
    mov rsi, [rdi + MEM_BLOCK_SIZE]
    add rsi, MEM_BLOCK_HEADER_SIZE
    ; RDI is al header pointer
    mov rax, 11         ; SYS_MUNMAP
    syscall
.done:
    ret

; --- [ Slab Allocator voor Nodes ] ---
_slab_alloc_node:
    push rbx
    mov rbx, [slab_node_head]
    test rbx, rbx
    jnz .use_existing
    
    ; Geen vrije nodes, alloceer nieuwe pagina
    mov rdi, SLAB_BLOCK_SIZE
    call _mem_alloc
    test rax, rax
    jz .error
    
    ; Verdeel pagina in nodes en link ze
    mov rbx, rax
    mov rcx, (SLAB_BLOCK_SIZE / SLAB_NODE_SIZE) - 1
    mov rdi, rbx
.link_loop:
    lea rsi, [rdi + SLAB_NODE_SIZE]
    mov [rdi], rsi      ; node->next = next_node
    mov rdi, rsi
    loop .link_loop
    mov qword [rdi], 0  ; Laatste is null

.use_existing:
    mov rax, rbx
    mov rsi, [rbx]      ; rsi = node->next
    mov [slab_node_head], rsi
    pop rbx
    ret
.error:
    xor rax, rax
    pop rbx
    ret

_slab_free_node:
    test rdi, rdi
    jz .done
    mov rsi, [slab_node_head]
    mov [rdi], rsi      ; node->next = current_head
    mov [slab_node_head], rdi
.done:
    ret

; --- Interne helpers ---
_internal_brk_alloc:
    ; Bestaande brk implementatie (vereenvoudigd)
    ; (Voor productie zou hier een volledige free-list manager zitten)
    mov rsi, [heap_current]
    test rsi, rsi
    jnz .ready
    mov rax, 12 ; SYS_BRK
    xor rdi, rdi
    syscall
    mov [heap_start], rax
    mov [heap_current], rax
    mov rsi, rax
.ready:
    mov rdi, rsi
    add rdi, r12
    add rdi, MEM_BLOCK_HEADER_SIZE
    mov rax, 12 ; SYS_BRK
    syscall
    mov rax, rsi
    mov [heap_current], rdi
    mov [rax + MEM_BLOCK_SIZE], r12
    mov qword [rax + MEM_BLOCK_FLAGS], 0
    add rax, MEM_BLOCK_HEADER_SIZE
    ret

; --- [ Geheugen Kopiëren ] ---
_mem_copy:
    mov rcx, rdx
    rep movsb
    ret

; --- [ Geheugen Vullen ] ---
_mem_set:
    mov rax, rsi
    mov rcx, rdx
    rep stosb
    ret

; --- [ Geheugen Vergelijken ] ---
_mem_compare:
    mov rcx, rdx
    repe cmpsb
    je .equal
    movzx rax, byte [rdi-1]
    movzx rbx, byte [rsi-1]
    sub rax, rbx
    ret
.equal:
    xor rax, rax
    ret
