; test_ui_advanced.asm - Interactive test for enhanced Viewport features
%include "algemeen.mac"
%include "screen.mac"
%include "cursor_v2.mac"

section .data
    msg_info    db "Professional ASM UI Advanced Test", 0
    msg_instr   db "Controls: [W/S] Scroll, [A/D] Move, [C] Clear, [Q] Quit", 0
    msg_vp      db "Line #", 0
    vp_title    db "Interactive View", 0
    
section .bss
    line_num_buf resb 16

section .text
    global _start
    extern TerminalRawMode, TerminalResetMode, ReadChar, IsKeyAvailable, PrintString, _int_to_str
    extern _screen_clear, _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_set_color, _viewport_set_border, _viewport_set_title
    extern _viewport_clear, _viewport_move, _cursor_goto_xy

_start:
    @cls
    call TerminalRawMode
    
    ; Create Viewport
    @vp_create 5, 5, 40, 10, 50
    mov r12, rax ; Save VP pointer
    
    @vp_set_border r12, 1
    @vp_set_title  r12, vp_title
    @vp_set_color  r12, 2, 0 ; Green
    
    ; Fill viewport with some lines
    mov rcx, 30
.fill_loop:
    push rcx
    
    ; Write "Line #[N]"
    mov rdi, msg_vp
    mov rsi, 2
    mov rdx, rcx
    dec rdx
    mov rcx, msg_vp
    @vp_write r12, 2, rdx, rcx
    
    ; Convert RCX to string and append
    pop rcx
    push rcx
    mov rax, rcx
    mov rdi, line_num_buf
    call _int_to_str
    
    mov rdx, rcx
    dec rdx
    mov rcx, line_num_buf
    @vp_write r12, 10, rdx, rcx
    
    pop rcx
    loop .fill_loop

    @vp_render r12

    ; Main interaction loop
.input_loop:
    @goto_xy 1, 1
    mov rdi, msg_info
    call PrintString
    @goto_xy 2, 1
    mov rdi, msg_instr
    call PrintString

    call ReadChar
    cmp al, 'q'
    je .exit
    cmp al, 'Q'
    je .exit
    
    cmp al, 'w'
    je .scroll_up
    cmp al, 's'
    je .scroll_down
    
    cmp al, 'a'
    je .move_left
    cmp al, 'd'
    je .move_right
    
    cmp al, 'c'
    je .clear_vp
    
    jmp .input_loop

.scroll_up:
    @vp_scroll r12, -1
    @vp_render r12
    jmp .input_loop

.scroll_down:
    @vp_scroll r12, 1
    @vp_render r12
    jmp .input_loop

.move_left:
    ; Simpele move: huidige X verlagen
    mov rax, [r12 + VP_X]
    test rax, rax
    jz .input_loop
    dec rax
    mov rsi, rax
    mov rdx, [r12 + VP_Y]
    @vp_move r12, rsi, rdx
    @cls
    @vp_render r12
    jmp .input_loop

.move_right:
    mov rax, [r12 + VP_X]
    inc rax
    mov rsi, rax
    mov rdx, [r12 + VP_Y]
    @vp_move r12, rsi, rdx
    @cls
    @vp_render r12
    jmp .input_loop

.clear_vp:
    @vp_clear r12
    @vp_render r12
    jmp .input_loop

.exit:
    call TerminalResetMode
    @cls
    @exit 0
