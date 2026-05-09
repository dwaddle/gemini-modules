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
_mem_alloc:
    @save_callee_saved
    mov r12, rdi
    add rdi, MEM_BLOCK_HEADER_SIZE
    
    cmp r12, 4032
    ja .use_mmap
    
    ; Search free list first (First Fit)
    mov rdi, [free_list_head]
.search_loop:
    test rdi, rdi
    jz .extend_heap
    
    mov rax, [rdi + MEM_BLOCK_SIZE]
    cmp rax, r12
    jae .found_free
    
    mov rdi, [rdi + MEM_BLOCK_NEXT]
    jmp .search_loop

.found_free:
    ; RDI is found header
    push rdi
    call _remove_from_free_list
    pop rdi
    and qword [rdi + MEM_BLOCK_FLAGS], ~MEM_FLAG_FREE
    add rdi, MEM_BLOCK_HEADER_SIZE
    mov rax, rdi
    jmp .done

.extend_heap:
    call _internal_brk_alloc
    jmp .done

.use_mmap:
    mov rsi, rdi
    xor rdi, rdi
    mov rdx, 3
    mov r10, 34
    mov r8, -1
    xor r9, r9
    mov rax, 9
    syscall
    test rax, rax
    js .error
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
    @save_callee_saved
    test rdi, rdi
    jz .done
    
    sub rdi, MEM_BLOCK_HEADER_SIZE
    mov r12, rdi
    
    mov rsi, [r12 + MEM_BLOCK_FLAGS]
    test rsi, MEM_FLAG_MMAP
    jnz .free_mmap
    
    ; Mark as free and add to list
    or qword [r12 + MEM_BLOCK_FLAGS], MEM_FLAG_FREE
    mov rdi, r12
    call _add_to_free_list
    
    ; Coalesce with next
    mov rbx, [r12 + MEM_BLOCK_SIZE]
    lea r13, [r12 + rbx + MEM_BLOCK_HEADER_SIZE]
    cmp r13, [heap_current]
    jae .done
    test qword [r13 + MEM_BLOCK_FLAGS], MEM_FLAG_FREE
    jz .done
    
    mov rdi, r13
    call _remove_from_free_list
    mov rax, [r13 + MEM_BLOCK_SIZE]
    add rax, MEM_BLOCK_HEADER_SIZE
    add [r12 + MEM_BLOCK_SIZE], rax
    jmp .done

.free_mmap:
    mov rsi, [r12 + MEM_BLOCK_SIZE]
    add rsi, MEM_BLOCK_HEADER_SIZE
    mov rdi, r12
    mov rax, 11
    syscall
.done:
    @restore_callee_saved
    ret

; --- [ Slab Allocator ] ---
_slab_alloc_node:
    push rbx
    mov rbx, [slab_node_head]
    test rbx, rbx
    jnz .use_existing
    mov rdi, SLAB_BLOCK_SIZE
    call _mem_alloc
    test rax, rax
    jz .error
    mov rbx, rax
    mov rcx, (SLAB_BLOCK_SIZE / SLAB_NODE_SIZE) - 1
    mov rdi, rbx
.link_loop:
    lea rsi, [rdi + SLAB_NODE_SIZE]
    mov [rdi], rsi
    mov rdi, rsi
    loop .link_loop
    mov qword [rdi], 0
.use_existing:
    mov rax, rbx
    mov rsi, [rbx]
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
    mov [rdi], rsi
    mov [slab_node_head], rdi
.done:
    ret

; --- Free List Helpers ---
_add_to_free_list:
    mov rsi, [free_list_head]
    mov [rdi + MEM_BLOCK_NEXT], rsi
    mov qword [rdi + MEM_BLOCK_PREV], 0
    test rsi, rsi
    jz .set_head
    mov [rsi + MEM_BLOCK_PREV], rdi
.set_head:
    mov [free_list_head], rdi
    ret

_remove_from_free_list:
    mov rsi, [rdi + MEM_BLOCK_PREV]
    mov rdx, [rdi + MEM_BLOCK_NEXT]
    test rsi, rsi
    jz .rem_head
    mov [rsi + MEM_BLOCK_NEXT], rdx
    jmp .rem_next
.rem_head:
    mov [free_list_head], rdx
.rem_next:
    test rdx, rdx
    jz .rem_done
    mov [rdx + MEM_BLOCK_PREV], rsi
.rem_done:
    ret

; --- Internal Helpers ---
_internal_brk_alloc:
    mov rsi, [heap_current]
    test rsi, rsi
    jnz .ready
    mov rax, 12
    xor rdi, rdi
    syscall
    mov [heap_start], rax
    mov [heap_current], rax
    mov rsi, rax
.ready:
    mov rdi, rsi
    add rdi, r12
    add rdi, MEM_BLOCK_HEADER_SIZE
    mov rax, 12
    syscall
    mov rax, rsi
    mov [heap_current], rdi
    mov [rax + MEM_BLOCK_SIZE], r12
    mov qword [rax + MEM_BLOCK_FLAGS], 0
    add rax, MEM_BLOCK_HEADER_SIZE
    ret

_mem_copy:
    mov rcx, rdx
    rep movsb
    ret
_mem_set:
    mov rax, rsi
    mov rcx, rdx
    rep stosb
    ret
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
