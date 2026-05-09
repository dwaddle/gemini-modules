; test_ui_pro.asm - Pro UI features test: Alignment, Auto-scroll, Focus
%include "algemeen.mac"
%include "screen.mac"
%include "cursor_v2.mac"

section .data
    msg_info    db "Professional ASM Pro UI Test", 0
    msg_instr   db "[TAB] Toggle Focus | [L] Add Log | [Q] Quit", 0
    
    title_log   db "Real-time Log", 0
    title_align db "Alignment Demo", 0
    
    txt_left    db "Left Aligned", 0
    txt_center  db "Centered Text", 0
    txt_right   db "Right Aligned", 0
    
    log_msg     db "Log Entry #", 0
    
    current_focus db 0
    log_count     dq 0

section .bss
    log_buf     resb 32

section .text
    global _start
    extern TerminalRawMode, TerminalResetMode, ReadChar, IsKeyAvailable, PrintString, _int_to_str
    extern _screen_clear, _viewport_create, _viewport_write, _viewport_render, _viewport_scroll, _viewport_set_color, _viewport_set_border, _viewport_set_title
    extern _viewport_clear, _viewport_move, _viewport_write_aligned, _viewport_set_border_color, _viewport_set_focus, _cursor_goto_xy, _screen_flip

_start:
    @cls
    call TerminalRawMode
    
    ; 1. Log Viewport (Left)
    @vp_create 2, 5, 30, 10, 100
    mov r12, rax ; r12 = Log VP
    @vp_set_border r12, 1
    @vp_set_title  r12, title_log
    @vp_set_autoscroll r12, 1
    @vp_set_border_color r12, 2, 0 ; Green border
    
    ; 2. Align Viewport (Right)
    @vp_create 35, 5, 30, 10, 20
    mov r13, rax ; r13 = Align VP
    @vp_set_border r13, 1
    @vp_set_title  r13, title_align
    @vp_set_border_color r13, 7, 0 ; White border

    ; Demo alignment
    @vp_write_aligned r13, 2, txt_left,   ALIGN_LEFT
    @vp_write_aligned r13, 4, txt_center, ALIGN_CENTER
    @vp_write_aligned r13, 6, txt_right,  ALIGN_RIGHT
    
    call _update_display

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
    cmp al, 9 ; Tab
    je .toggle_focus
    cmp al, 'l'
    je .add_log
    cmp al, 'L'
    je .add_log
    
    jmp .input_loop

.toggle_focus:
    xor byte [current_focus], 1
    call _update_display
    jmp .input_loop

.add_log:
    inc qword [log_count]
    
    ; Build log message
    mov rdi, log_buf
    mov rsi, log_msg
    extern _str_copy
    call _str_copy
    
    mov rdi, log_buf
    extern _strlen
    call _strlen
    add rdi, rax
    
    mov rax, [log_count]
    call _int_to_str
    
    ; Write to log VP at the end (using log_count as Y, clamped by autoscroll)
    mov rdx, [log_count]
    dec rdx
    @vp_write r12, 1, rdx, log_buf
    
    @vp_render r12
    @screen_flip
    jmp .input_loop

.exit:
    call TerminalResetMode
    @cls
    @exit 0

_update_display:
    ; Update border colors based on focus
    cmp byte [current_focus], 0
    je .focus_log
    
    ; Focus Align
    @vp_set_border_color r12, 7, 0
    @vp_set_border_color r13, 3, 0 ; Yellow for focus
    jmp .render_all

.focus_log:
    @vp_set_border_color r12, 3, 0 ; Yellow for focus
    @vp_set_border_color r13, 7, 0

.render_all:
    @vp_render r12
    @vp_render r13
    @screen_flip
    ret
