; list.asm - Singly Linked List for x86_64
%include "algemeen.mac"

; Node structure:
; +0: next (dq)
; +8: data (dq)
NODE_SIZE equ 16
NODE_NEXT equ 0
NODE_DATA equ 8

section .text
    global _list_push_front
    global _list_pop_front
    global _list_push_back
    global _list_free
    extern _mem_alloc, _mem_free

; --- [ List: Push Front ] ---
; Input: RDI = Pointer to Head Pointer, RSI = Data
_list_push_front:
    @save_context
    mov r12, rdi        ; R12 = HeadPtrPtr
    mov r13, rsi        ; R13 = Data
    
    ; Allocate new node
    mov rdi, NODE_SIZE
    call _mem_alloc
    test rax, rax
    jz .done
    
    mov r14, rax        ; R14 = New Node
    mov [r14 + NODE_DATA], r13
    
    mov rbx, [r12]      ; Current head
    mov [r14 + NODE_NEXT], rbx
    mov [r12], r14      ; Update head
    
.done:
    @restore_context
    ret

; --- [ List: Pop Front ] ---
; Input: RDI = Pointer to Head Pointer
; Output: RAX = Data (or 0 if empty)
_list_pop_front:
    @save_context
    mov r12, rdi        ; R12 = HeadPtrPtr
    mov r13, [r12]      ; R13 = Current Head
    test r13, r13
    jz .empty
    
    mov rax, [r13 + NODE_DATA]
    push rax            ; Save data to return
    
    mov rbx, [r13 + NODE_NEXT]
    mov [r12], rbx      ; Update head
    
    ; Free node
    mov rdi, r13
    call _mem_free
    
    pop rax
    jmp .done

.empty:
    xor rax, rax
.done:
    @restore_context
    ret

; --- [ List: Push Back ] ---
; Input: RDI = Pointer to Head Pointer, RSI = Data
_list_push_back:
    @save_context
    mov r12, rdi        ; R12 = HeadPtrPtr
    mov r13, rsi        ; R13 = Data
    
    ; Allocate new node
    mov rdi, NODE_SIZE
    call _mem_alloc
    test rax, rax
    jz .done
    
    mov r14, rax        ; R14 = New Node
    mov [r14 + NODE_DATA], r13
    mov qword [r14 + NODE_NEXT], 0
    
    mov rbx, [r12]      ; Current head
    test rbx, rbx
    jnz .find_tail
    
    mov [r12], r14      ; List was empty, new node is head
    jmp .done

.find_tail:
    mov rsi, rbx        ; RSI = current node
.tail_loop:
    mov rdx, [rsi + NODE_NEXT]
    test rdx, rdx
    jz .found_tail
    mov rsi, rdx
    jmp .tail_loop

.found_tail:
    mov [rsi + NODE_NEXT], r14
    
.done:
    @restore_context
    ret

; --- [ List: Free ] ---
; Input: RDI = Pointer to Head Pointer, RSI = Free Function (Optional, 0 if none)
_list_free:
    @save_context
    mov r12, rdi        ; R12 = HeadPtrPtr
    mov r13, rsi        ; R13 = FreeFunc
    
    mov r14, [r12]      ; R14 = Current node
.loop:
    test r14, r14
    jz .done
    
    mov r15, [r14 + NODE_NEXT] ; Save next
    
    ; Free data if function provided
    test r13, r13
    jz .free_node
    mov rdi, [r14 + NODE_DATA]
    call r13

.free_node:
    mov rdi, r14
    call _mem_free
    
    mov r14, r15
    jmp .loop

.done:
    mov qword [r12], 0
    @restore_context
    ret
