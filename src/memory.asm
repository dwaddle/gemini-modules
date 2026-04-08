; memory.asm - Geheugenbeheer en Manipulatie voor x86_64
%include "syscalls.inc"
%include "algemeen.mac"

; --- Memory Block Header Definition ---
; Placed at the beginning of each allocated/free chunk.
; Size: 32 bytes
; +0: next_free (dq)  ; Pointer to next block in free list
; +8: prev_free (dq)  ; Pointer to previous block in free list
; +16: size (dq)      ; Size of the user-accessible data area (excluding header)
; +24: flags (dq)     ; e.g., 0=allocated, 1=free
MEM_BLOCK_HEADER_SIZE equ 32
MEM_BLOCK_NEXT_FREE   equ 0
MEM_BLOCK_PREV_FREE   equ 8
MEM_BLOCK_SIZE        equ 16
MEM_BLOCK_FLAGS       equ 24
MEM_BLOCK_FLAG_FREE   equ 1
MEM_BLOCK_FLAG_ALLOC  equ 0

section .data
    heap_start    dq 0
    heap_current  dq 0
    free_list_head dq 0 ; Pointer to the first block in the free list

section .text
    global _mem_alloc, _mem_free, _mem_copy, _mem_set, _mem_compare

; --- Helper Function: Get Block Header from User Pointer ---
; Input: RDI = Pointer to user data
; Output: RAX = Pointer to block header
_get_block_header:
    @save_context
    mov rax, rdi            ; User data pointer
    sub rax, MEM_BLOCK_HEADER_SIZE ; Move back to header
    @restore_context
    ret

; --- Helper Function: Get User Data Pointer from Header ---
; Input: RDI = Pointer to block header
; Output: RAX = Pointer to user data
_get_user_ptr:
    @save_context
    mov rax, rdi            ; Block header pointer
    add rax, MEM_BLOCK_HEADER_SIZE ; Move forward to user data
    @restore_context
    ret

; --- Helper Function: Remove Block from Free List ---
; Input: RDI = Pointer to block header to remove
; Output: RAX = 0 on success, non-zero on error
_remove_from_free_list:
    @save_context
    mov rbx, [free_list_head] ; Current head
    cmp rdi, rbx            ; Is this the head?
    je .remove_head

    ; Not the head, find its predecessor
    mov rsi, rdi            ; Current block (RDI)
    add rsi, MEM_BLOCK_PREV_FREE
    mov rsi, [rsi]          ; rsi now points to predecessor (if it exists)
    
    ; Check if predecessor is valid before accessing it
    cmp rsi, 0
    je .error_remove_from_free_list ; Predecessor not found (should not happen if RDI is in list and not head)

    ; Link predecessor's next_free to current block's next_free
    mov rbx, rdi            ; Current block (RDI)
    add rbx, MEM_BLOCK_NEXT_FREE
    mov rbx, [rbx]          ; rbx now points to current block's next_free
    
    add rsi, MEM_BLOCK_NEXT_FREE
    mov [rsi], rbx          ; predecessor.next_free = current.next_free
    
    ; Link successor's prev_free to current block's prev_free
    mov rsi, rdi            ; Current block (RDI)
    add rsi, MEM_BLOCK_NEXT_FREE
    mov rsi, [rsi]          ; rsi now points to current block's next_free (successor)

    cmp rsi, 0              ; If successor exists
    jne .update_successor_prev
    jmp .done_remove_from_free_list ; No successor, we are done

.remove_head:
    mov rbx, rdi            ; Current block (RDI)
    add rbx, MEM_BLOCK_NEXT_FREE
    mov rbx, [rbx]          ; rbx now points to current block's next_free
    mov [free_list_head], rbx ; Update head

    ; If new head exists, update its prev_free
    cmp rbx, 0
    jne .update_new_head_prev
    jmp .done_remove_from_free_list

.update_new_head_prev:
    add rbx, MEM_BLOCK_PREV_FREE
    xor rax, rax            ; Clear previous pointer
    mov [rbx], rax
    jmp .done_remove_from_free_list

.update_successor_prev:
    add rsi, MEM_BLOCK_PREV_FREE
    mov rbx, rdi            ; Current block (RDI)
    add rbx, MEM_BLOCK_PREV_FREE
    mov rbx, [rbx]          ; rbx now points to current block's prev_free
    mov [rsi], rbx          ; successor.prev_free = current.prev_free

.done_remove_from_free_list:
    xor rax, rax            ; Success
    @restore_context
    ret
.error_remove_from_free_list:
    mov rax, 1              ; Error
    @restore_context
    ret

; --- Helper Function: Add Block to Free List (at head) ---
; Input: RDI = Pointer to block header to add
; Output: RAX = 0 on success, non-zero on error
_add_to_free_list:
    @save_context
    mov rbx, [free_list_head] ; Get current head
    
    ; Set new block's pointers
    mov [rdi + MEM_BLOCK_NEXT_FREE], rbx  ; new_block.next_free = current_head
    mov [rdi + MEM_BLOCK_PREV_FREE], 0     ; new_block.prev_free = NULL
    
    ; Update current head's prev_free if it exists
    cmp rbx, 0
    jne .update_old_head_prev
    
    ; If no current head, new block is the only one
    mov [free_list_head], rdi ; Update head
    jmp .done_add_to_free_list

.update_old_head_prev:
    add rbx, MEM_BLOCK_PREV_FREE
    mov [rbx], rdi          ; current_head.prev_free = new_block
    mov [free_list_head], rdi ; Update head
    
.done_add_to_free_list:
    xor rax, rax            ; Success
    @restore_context
    ret

; --- [ Geheugen Alloceren (malloc) ] ---
; Input: RDI = Aantal bytes requested by user
; Output: RAX = Adres van gealloceerd blok (user data), of 0 bij fout
_mem_alloc:
    @save_context
    mov r12, rdi            ; Save requested size in r12 (user_data_size)

    ; 0. Initialize heap if needed
    mov rax, [heap_start]
    test rax, rax
    jnz .heap_ready
    mov rdi, 0              ; Get current break
    mov rax, SYS_BRK
    syscall
    mov [heap_start], rax
    mov [heap_current], rax
.heap_ready:

    ; 1. Try to find a suitable block in the free list
    mov rbx, [free_list_head] ; Start at the head of the free list
    test rbx, rbx           ; Is the free list empty?
    jnz .search_free_list   ; If not empty, search it

.no_free_blocks:
    ; 2. If no free blocks or list is empty, extend the heap
    ; Calculate total size needed: header + requested size
    mov rdi, r12            ; Requested user data size
    add rdi, MEM_BLOCK_HEADER_SIZE ; Add header size
    
    ; Get current heap break and request extension
    mov rsi, [heap_current] ; Get current heap break
    add rsi, rdi            ; rsi = new heap break position (current + size_needed)
    mov rdi, rsi            ; Pass new break position to brk
    mov rax, SYS_BRK
    syscall
    mov r8, rax             ; r8 = new heap break position returned by syscall
    
    ; Check if brk failed
    cmp r8, [heap_current]
    jbe .error_alloc        ; If new break is not greater than current, it failed

    ; Allocate the new block. The actual block starts at the old heap_current.
    mov r9, [heap_current]  ; r9 = start of the new block (header address)
    mov [heap_current], r8  ; Update heap_current to the new break

    ; Initialize the header for the new block
    mov [r9 + MEM_BLOCK_SIZE], r12 ; Store user requested size
    mov [r9 + MEM_BLOCK_FLAGS], MEM_BLOCK_FLAG_ALLOC ; Mark as allocated
    mov [r9 + MEM_BLOCK_NEXT_FREE], 0 ; Not in free list (as it's newly allocated)
    mov [r9 + MEM_BLOCK_PREV_FREE], 0 ; Not in free list

    ; Return pointer to user data
    mov rdi, r9             ; rdi = block header pointer
    call _get_user_ptr      ; RAX = user data pointer
    jmp .done_alloc

.search_free_list:
    ; Iterate through the free list to find a suitable block
    mov rbx, [free_list_head] ; Start with head
.search_loop:
    cmp rbx, 0              ; End of list?
    je .no_suitable_free_block ; If yes, go to heap extension

    ; Get size of current free block (user data area size)
    mov r10, [rbx + MEM_BLOCK_SIZE] ; r10 = free_block_user_data_size

    ; Check if this block is large enough for requested user data + header
    cmp r10, r12
    jl .next_free_block     ; If free block size < requested user data size, try next block

    ; Found a suitable block (rbx points to its header)
    mov rdi, rbx            ; rdi = pointer to the found free block header
    call _remove_from_free_list ; Remove it from the free list
    cmp rax, 0              ; Check if removal was successful (rax=0 on error)
    jne .error_alloc        ; If error removing from free list, fail allocation

    ; Now, check if we can split this block
    ; Split if (free_block_size >= requested_size + header_size + minimum_free_block_overhead)
    ; free_block_size is in r10 (user_data_size)
    ; requested_size is in r12 (user_data_size)
    mov r11, r10            ; r11 = free_block_user_data_size
    sub r11, r12            ; r11 = remaining_size after taking requested user data size
    
    ; Minimum overhead for a new free block: header_size + minimal_user_data_size (e.g., 8 bytes)
    cmp r11, MEM_BLOCK_HEADER_SIZE + 8
    jl .dont_split          ; If not enough space for a new free block, use the whole block

    ; Split the block:
    ; 1. Update size of the allocated part (rbx points to header)
    mov [rbx + MEM_BLOCK_SIZE], r12 ; Set size of the allocated part to user's request

    ; 2. Calculate and set up the new free block (the remainder)
    ; The new free block starts right after the allocated user data area
    mov rdi, rbx            ; rdi = pointer to current (allocated) block header
    add rdi, r12            ; Move past user data area
    add rdi, MEM_BLOCK_HEADER_SIZE ; Move past header to user data part of the REMAINDER
    
    ; Calculate size of the new free block's user data area
    sub r11, MEM_BLOCK_HEADER_SIZE ; r11 = size of remaining user data area
    mov [rdi + MEM_BLOCK_SIZE], r11 ; Set size of the new free block's user data area
    mov [rdi + MEM_BLOCK_FLAGS], MEM_BLOCK_FLAG_FREE ; Mark as free

    ; Add the new free block (remainder) to the free list
    call _add_to_free_list  ; rdi is already set to the new free block header
    cmp rax, 0              ; Check if add to free list was successful
    jne .error_alloc        ; If error adding to free list, fail allocation

    jmp .found_block        ; Jump to finalize the allocation using the split part

.dont_split:
    ; Use the entire found block, even if it's larger than needed
    ; The header at rbx already has the full size (r10), just need to update flags.
    ; The block's size is already stored in MEM_BLOCK_SIZE.

.found_block:
    ; Mark the block as allocated
    mov [rbx + MEM_BLOCK_FLAGS], MEM_BLOCK_FLAG_ALLOC
    
    ; Return pointer to user data
    mov rdi, rbx            ; rdi = block header pointer
    call _get_user_ptr      ; RAX = user data pointer
    jmp .done_alloc

.next_free_block:
    ; Move to the next free block in the list
    mov rbx, rbx            ; current block header (rbx)
    add rbx, MEM_BLOCK_NEXT_FREE
    mov rbx, [rbx]          ; rbx = pointer to next free block header
    jmp .search_loop

.no_suitable_free_block:
    ; Fallback to extending the heap (handled by .no_free_blocks logic)
    jmp .no_free_blocks

.error_alloc:
    xor rax, rax            ; Return NULL on error
    @restore_context
    ret

.done_alloc:
    @restore_context
    ret

; --- [ Geheugen Vrijgeven (free) ] ---
; Input: RDI = Pointer to user data of the block to free
; Output: None
_mem_free:
    @save_context
    cmp rdi, 0              ; If pointer is NULL, do nothing
    je .done_free

    ; Get the block header from the user data pointer
    mov rbx, rdi            ; rdi = user data ptr
    call _get_block_header  ; rax = header ptr
    mov rdi, rax            ; rdi = header ptr

    ; Check if block is already free
    mov rax, [rdi + MEM_BLOCK_FLAGS]
    cmp rax, MEM_BLOCK_FLAG_FREE
    je .done_free           ; Already free, do nothing

    ; Mark the block as free
    mov [rdi + MEM_BLOCK_FLAGS], MEM_BLOCK_FLAG_FREE
    
    ; Add the block to the head of the free list
    call _add_to_free_list
    cmp rax, 0              ; Check if add to free list was successful
    jne .error_free         ; If error adding to free list, fail (or handle appropriately)

    ; --- Coalescing Logic ---
    ; Check and merge with the next block if it's free
    ; Current block header is in rdi
    mov rbx, rdi            ; rbx = current block header
    mov r10, [rbx + MEM_BLOCK_SIZE] ; r10 = current block user data size
    add rbx, r10            ; Move to end of current user data
    add rbx, MEM_BLOCK_HEADER_SIZE  ; rbx = potential start of next block (header address)
    
    ; Check if next block exists and is free
    cmp rbx, [heap_current] ; If rbx >= heap_current, there's no next block within current heap
    jge .no_next_block_to_merge ; If next block is outside heap, cannot merge

    mov rsi, [rbx + MEM_BLOCK_FLAGS] ; rsi = flags of next block
    cmp rsi, MEM_BLOCK_FLAG_FREE
    jne .no_next_block_to_merge ; If next block is not free, cannot merge

    ; Next block is free, so merge it into the current block (rbx is header of next block)
    ; 1. Remove the 'next' block from the free list
    mov rdi, rbx            ; Pass header of 'next' block to remove
    call _remove_from_free_list
    cmp rax, 0              ; Check if removal was successful
    jne .no_next_block_to_merge ; If error, skip merging

    ; 2. Update the size of the current block (rbx is header of 'next' block, rdi is header of current block)
    mov rsi, [rbx + MEM_BLOCK_SIZE] ; next_block_user_data_size
    add r10, rsi            ; total_user_data_size = current_size + next_size
    add r10, MEM_BLOCK_HEADER_SIZE ; add size of the next block's header
    mov [rdi + MEM_BLOCK_SIZE], r10 ; Update current block's total user data size

    ; We don't need to check for coalescing with the previous block here because
    ; if the previous block was free, it would have coalesced forward with this block
    ; when *it* was freed. This assumes freeing happens in a way that naturally
    ; leads to forward coalescing.

.no_next_block_to_merge:
    ; (Optional) More advanced coalescing could be added here to check the previous block
    ; by searching from heap_start or by maintaining prev_block pointers at the heap level.
    
    jmp .done_free

.error_free:
    ; Handle error if _add_to_free_list failed
    ; For now, just return
    @restore_context
    ret

.done_free:
    @restore_context
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
    movzx rax, byte [rdi-1] ; Get the byte that caused mismatch from buf1
    movzx rbx, byte [rsi-1] ; Get the byte that caused mismatch from buf2
    sub rax, rbx            ; Calculate difference
    jmp .done
.equal:
    xor rax, rax            ; All bytes matched
.done:
    @restore_context
    ret
