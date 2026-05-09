; gtop.asm - Interactive System Monitor
%include "algemeen.mac"
%include "screen.mac"
%include "file.mac"
%include "string.mac"
%include "memory.mac"
%include "screen_constants.inc"
%include "syscalls.inc"

%define SYS_NANOSLEEP 35
%define SYS_STATFS    137

; dirent64 struct offsets
%define D64_RECLEN   16
%define D64_NAME     19

section .data
    path_meminfo db "/proc/meminfo", 0
    path_stat    db "/proc/stat", 0
    path_net     db "/proc/net/dev", 0
    path_root    db "/", 0
    path_proc    db "/proc", 0
    
    title_cpu  db "CPU USAGE", 0
    title_mem  db "MEMORY USAGE", 0
    title_net  db "NETWORK (wlan0)", 0
    title_disk db "DISK (/) ", 0
    title_proc db "PROCESS LIST (TAB to Focus, W/S to Scroll, Q to Quit)", 0
    
    lbl_cpu_pct db "CPU %: ", 0
    lbl_total  db "Total: ", 0
    lbl_avail  db "Avail: ", 0
    lbl_used   db "Used:  ", 0
    lbl_rx     db "RX:    ", 0
    lbl_tx     db "TX:    ", 0
    fmt_pct    db "%", 0
    fmt_kb     db " KB", 0
    fmt_gb     db " GB", 0
    fmt_sep    db " | ", 0
    
    proc_path_pre db "/proc/", 0
    proc_path_suf db "/comm", 0
    tag_cpu    db "cpu ", 0
    tag_mem_total db "MemTotal:", 0
    tag_mem_avail db "MemAvailable:", 0
    tag_wlan0     db "wlan0:", 0
    dbg_up        db "[UP]", 0
    dbg_lp        db "[LP]", 0
    dbg_s1        db "[S1]", 0
    dbg_s2        db "[S2]", 0

    timespec_100ms:
        dq 0, 100000000 ; 100ms for responsiveness

section .bss
    vp_cpu      resq 1
    vp_mem      resq 1
    vp_net      resq 1
    vp_disk     resq 1
    vp_proc     resq 1
    
    vp_focus    resq 1 
    loop_tick   resq 1 

    proc_buf    resb 16384
    file_buf    resb 4096
    num_buf     resb 64
    statfs_buf  resb 128
    path_buf    resb 256
    comm_buf    resb 256
    
    prev_total  resq 1
    prev_idle   resq 1
    prev_rx     resq 1
    prev_tx     resq 1

section .text
    global _start
    extern _screen_clear, _screen_hide_cursor, _screen_show_cursor, _screen_reset_color
    extern _viewport_create, _viewport_write, _viewport_render, _viewport_set_border, _viewport_set_title, _viewport_set_color, _viewport_scroll
    extern _cursor_goto_xy, PrintString, ReadChar, IsKeyAvailable, TerminalRawMode, TerminalResetMode
    extern _file_open, _file_read, _file_close
    extern _str_find, _str_to_int, _int_to_str, _strlen, _str_is_numeric, _str_copy, _str_concat, _mem_set

_start:
    call _screen_clear
    call _screen_hide_cursor
    
    mov rdi, dbg_s1
    call PrintString
    call TerminalRawMode
    mov rdi, dbg_s2
    call PrintString
    
    ; Setup Viewports
    mov rdi, 2
    mov rsi, 2
    mov rdx, 35
    mov rcx, 3
    mov r8, 5
    call _viewport_create
    mov [vp_cpu], rax
    
    mov rdi, 40
    mov rsi, 2
    mov rdx, 35
    mov rcx, 4
    mov r8, 5
    call _viewport_create
    mov [vp_net], rax

    mov rdi, 2
    mov rsi, 7
    mov rdx, 35
    mov rcx, 5
    mov r8, 5
    call _viewport_create
    mov [vp_mem], rax

    mov rdi, 40
    mov rsi, 8
    mov rdx, 35
    mov rcx, 4
    mov r8, 5
    call _viewport_create
    mov [vp_disk], rax

    mov rdi, 2
    mov rsi, 14
    mov rdx, 73
    mov rcx, 10
    mov r8, 100 ; Larger buffer for scrolling
    call _viewport_create
    mov [vp_proc], rax
    
    ; Initial Focus
    mov rax, [vp_proc]
    mov [vp_focus], rax

    ; Setup titles and borders
    mov rdi, [vp_cpu]
    mov rsi, title_cpu
    call _viewport_set_title
    mov rdi, [vp_cpu]
    mov rsi, VPF_BORDER
    call _viewport_set_border
    
    mov rdi, [vp_mem]
    mov rsi, title_mem
    call _viewport_set_title
    mov rdi, [vp_mem]
    mov rsi, VPF_BORDER
    call _viewport_set_border

    mov rdi, [vp_net]
    mov rsi, title_net
    call _viewport_set_title
    mov rdi, [vp_net]
    mov rsi, VPF_BORDER
    call _viewport_set_border

    mov rdi, [vp_disk]
    mov rsi, title_disk
    call _viewport_set_title
    mov rdi, [vp_disk]
    mov rsi, VPF_BORDER
    call _viewport_set_border

    mov rdi, [vp_proc]
    mov rsi, title_proc
    call _viewport_set_title
    mov rdi, [vp_proc]
    mov rsi, VPF_BORDER
    call _viewport_set_border

    mov qword [loop_tick], 0

.main_loop:
    push rdi
    mov rdi, dbg_lp
    call PrintString
    pop rdi
    call IsKeyAvailable
    test rax, rax
    jz .no_input
    
    call ReadChar 
    cmp al, 'q'
    je .exit_prog
    cmp al, 'Q'
    je .exit_prog
    cmp al, 9 
    je .switch_f
    cmp al, 'w'
    je .scr_up
    cmp al, 's'
    je .scr_down
    jmp .no_input

.exit_prog:
    call TerminalResetMode
    call _screen_show_cursor
    @exit 0

.switch_f:
    mov rax, [vp_focus]
    mov rbx, [vp_cpu]
    cmp rax, rbx
    je .f_net
    mov rbx, [vp_net]
    cmp rax, rbx
    je .f_mem
    mov rbx, [vp_mem]
    cmp rax, rbx
    je .f_disk
    mov rbx, [vp_disk]
    cmp rax, rbx
    je .f_proc
    mov rax, [vp_cpu]
    jmp .set_f
.f_net: mov rax, [vp_net]
    jmp .set_f
.f_mem: mov rax, [vp_mem]
    jmp .set_f
.f_disk: mov rax, [vp_disk]
    jmp .set_f
.f_proc: mov rax, [vp_proc]
.set_f:
    mov [vp_focus], rax
    jmp .no_input

.scr_up:
    mov rdi, [vp_focus]
    mov rsi, -1
    call _viewport_scroll
    jmp .no_input

.scr_down:
    mov rdi, [vp_focus]
    mov rsi, 1
    call _viewport_scroll
    jmp .no_input

.no_input:
    inc qword [loop_tick]
    cmp qword [loop_tick], 10
    jb .render_only
    
    mov qword [loop_tick], 0
    call update_cpu
    call update_mem
    call update_net
    call update_disk
    call update_processes

.render_only:
    mov r12, [vp_cpu]
    call apply_focus_color
    mov rdi, r12
    call _viewport_render
    
    mov r12, [vp_mem]
    call apply_focus_color
    mov rdi, r12
    call _viewport_render
    
    mov r12, [vp_net]
    call apply_focus_color
    mov rdi, r12
    call _viewport_render
    
    mov r12, [vp_disk]
    call apply_focus_color
    mov rdi, r12
    call _viewport_render
    
    mov r12, [vp_proc]
    call apply_focus_color
    mov rdi, r12
    call _viewport_render

    mov rax, SYS_NANOSLEEP
    mov rdi, timespec_100ms
    xor rsi, rsi
    syscall
    jmp .main_loop

apply_focus_color:
    mov rdi, r12
    mov rdx, COL_BLACK
    mov rsi, COL_WHITE
    mov rax, [vp_focus]
    cmp r12, rax
    je .afc_set
    mov rsi, COL_CYAN 
.afc_set:
    call _viewport_set_color
    ret

update_processes:
    @save_context
    push rdi
    mov rdi, dbg_up
    call PrintString
    pop rdi
    mov rdi, [vp_proc]
    call clear_viewport
    
    mov rdi, path_proc
    mov rsi, 0x10000 
    xor rdx, rdx
    mov rax, SYS_OPEN
    syscall
    test rax, rax
    js .up_done
    mov r12, rax 
    
    mov rdi, r12
    mov rsi, proc_buf
    mov rdx, 16384
    mov rax, SYS_GETDENTS64
    syscall
    mov r13, rax
    
    mov rdi, r12
    mov rax, SYS_CLOSE
    syscall
    
    test r13, r13
    jle .up_done
    
    xor r14, r14 
    xor r15, r15 
.up_loop:
    cmp r14, r13
    jae .up_done
    cmp r15, 90 ; Limit buffer fill
    jae .up_done
    
    mov rsi, proc_buf
    add rsi, r14
    
    movzx rbx, word [rsi + D64_RECLEN] ; Save reclen
    lea rdx, [rsi + D64_NAME] ; PID Name
    
    push rbx
    push rdx
    
    mov rdi, rdx
    call _str_is_numeric
    test rax, rax
    jz .up_skip
    
    ; Construct /proc/[pid]/comm
    mov rdi, path_buf
    mov rsi, proc_path_pre
    call _str_copy
    mov rdi, path_buf
    mov rsi, [rsp] ; Original RDX
    call _str_concat
    mov rdi, path_buf
    mov rsi, proc_path_suf
    call _str_concat
    
    ; Read comm
    mov rdi, path_buf
    mov rsi, 0
    call _file_open
    test rax, rax
    js .up_no_comm
    mov r12, rax
    mov rdi, r12
    mov rsi, comm_buf
    mov rdx, 255
    call _file_read
    test rax, rax
    jle .up_close_comm
    mov byte [rsi + rax - 1], 0
.up_close_comm:
    mov rdi, r12
    call _file_close
    jmp .up_write
.up_no_comm:
    mov byte [comm_buf], '?'
    mov byte [comm_buf + 1], 0
.up_write:
    mov rdi, [vp_proc]
    mov rsi, 1
    mov rdx, r15
    mov rcx, [rsp] ; Original PID name
    call _viewport_write
    
    mov rdi, [vp_proc]
    mov rsi, 8
    mov rdx, r15
    mov rcx, fmt_sep
    call _viewport_write
    
    mov rdi, [vp_proc]
    mov rsi, 11
    mov rdx, r15
    mov rcx, comm_buf
    call _viewport_write
    inc r15

.up_skip:
    pop rdx
    pop rbx
    add r14, rbx
    jmp .up_loop
.up_done:
    @restore_context
    ret

clear_viewport:
    @save_context
    mov rbx, rdi
    mov rax, [rbx + 16] 
    mov rcx, [rbx + 40] 
    mul rcx
    mov rdi, [rbx + 32] 
    mov rsi, ' '
    mov rdx, rax
    call _mem_set
    @restore_context
    ret

update_cpu:
    @save_context
    mov rdi, path_stat
    mov rsi, 0
    call _file_open
    test rax, rax
    js .uc_done
    mov r12, rax
    mov rdi, r12
    mov rsi, file_buf
    mov rdx, 4096
    call _file_read
    call _file_close
    mov rdi, file_buf
    mov rsi, tag_cpu
    call _str_find
    test rax, rax
    jz .uc_done
    add rax, 4
    mov rsi, rax
    mov r13, 0
    mov r14, 0
    mov rcx, 7
.uc_loop:
    push rcx
    call skip_spaces
    call parse_long
    add r13, rax
    pop rcx
    cmp rcx, 4
    jne .uc_ni
    mov r14, rax
.uc_ni: loop .uc_loop
    mov rax, r13
    sub rax, [prev_total]
    mov rbx, rax
    mov rax, r14
    sub rax, [prev_idle]
    mov rcx, rax
    mov [prev_total], r13
    mov [prev_idle], r14
    test rbx, rbx
    jz .uc_done
    mov rax, rbx
    sub rax, rcx
    imul rax, 100
    xor rdx, rdx
    div rbx
    push rax
    mov rdi, [vp_cpu]
    mov rsi, 2
    mov rdx, 1
    mov rcx, lbl_cpu_pct
    call _viewport_write
    pop rax
    mov rdi, num_buf
    call _int_to_str
    mov rdi, [vp_cpu]
    mov rsi, 10
    mov rdx, 1
    mov rcx, num_buf
    call _viewport_write
    mov rdi, [vp_cpu]
    mov rsi, 13
    mov rdx, 1
    mov rcx, fmt_pct
    call _viewport_write
.uc_done: @restore_context
    ret

update_mem:
    @save_context
    mov rdi, path_meminfo
    mov rsi, 0
    call _file_open
    test rax, rax
    js .um_done
    mov r12, rax
    mov rdi, r12
    mov rsi, file_buf
    mov rdx, 8192
    call _file_read
    call _file_close
    mov rdi, file_buf
    mov rsi, tag_mem_total
    call _str_find
    test rax, rax
    jz .um_done
    mov rsi, rax
    call skip_to_number
    call parse_long
    mov r13, rax
    mov rdi, file_buf
    mov rsi, tag_mem_avail
    call _str_find
    test rax, rax
    jz .um_done
    mov rsi, rax
    call skip_to_number
    call parse_long
    mov r14, rax
    mov rax, r13
    sub rax, r14
    mov r15, rax
    mov rdi, [vp_mem]
    mov rsi, 2
    mov rdx, 1
    mov rcx, lbl_total
    call _viewport_write
    mov rax, r13
    mov rdi, num_buf
    call _int_to_str
    mov rdi, [vp_mem]
    mov rsi, 10
    mov rdx, 1
    mov rcx, num_buf
    call _viewport_write
    mov rdi, [vp_mem]
    mov rsi, 2
    mov rdx, 2
    mov rcx, lbl_avail
    call _viewport_write
    mov rax, r14
    mov rdi, num_buf
    call _int_to_str
    mov rdi, [vp_mem]
    mov rsi, 10
    mov rdx, 2
    mov rcx, num_buf
    call _viewport_write
    mov rdi, [vp_mem]
    mov rsi, 2
    mov rdx, 3
    mov rcx, lbl_used
    call _viewport_write
    mov rax, r15
    mov rdi, num_buf
    call _int_to_str
    mov rdi, [vp_mem]
    mov rsi, 10
    mov rdx, 3
    mov rcx, num_buf
    call _viewport_write
.um_done: @restore_context
    ret

update_net:
    @save_context
    mov rdi, path_net
    mov rsi, 0
    call _file_open
    test rax, rax
    js .un_done
    mov r12, rax
    mov rdi, r12
    mov rsi, file_buf
    mov rdx, 8192
    call _file_read
    call _file_close
    mov rdi, file_buf
    mov rsi, tag_wlan0
    call _str_find
    test rax, rax
    jz .un_done
    add rax, 6
    mov rsi, rax
    call parse_long
    mov r13, rax
    mov rcx, 7
.un_skip:
    push rcx
.un_sn:
    mov al, [rsi]
    test al, al
    jz .un_pd
    cmp al, ' '
    je .un_as
    inc rsi
    jmp .un_sn
.un_as:
    call skip_spaces
    pop rcx
    loop .un_skip
    call parse_long
    mov r14, rax
    mov rax, r13
    sub rax, [prev_rx]
    mov r15, rax
    mov rax, r14
    sub rax, [prev_tx]
    mov rbx, rax
    mov [prev_rx], r13
    mov [prev_tx], r14
    mov rdi, [vp_net]
    mov rsi, 2
    mov rdx, 1
    mov rcx, lbl_rx
    call _viewport_write
    mov rax, r15
    shr rax, 10
    mov rdi, num_buf
    call _int_to_str
    mov rdi, [vp_net]
    mov rsi, 10
    mov rdx, 1
    mov rcx, num_buf
    call _viewport_write
    mov rdi, [vp_net]
    mov rsi, 22
    mov rdx, 1
    mov rcx, fmt_kb
    call _viewport_write
    mov rdi, [vp_net]
    mov rsi, 2
    mov rdx, 2
    mov rcx, lbl_tx
    call _viewport_write
    mov rax, rbx
    shr rax, 10
    mov rdi, num_buf
    call _int_to_str
    mov rdi, [vp_net]
    mov rsi, 10
    mov rdx, 2
    mov rcx, num_buf
    call _viewport_write
    mov rdi, [vp_net]
    mov rsi, 22
    mov rdx, 2
    mov rcx, fmt_kb
    call _viewport_write
    jmp .un_done
.un_pd: pop rcx
.un_done: @restore_context
    ret

update_disk:
    @save_context
    mov rax, SYS_STATFS
    mov rdi, path_root
    mov rsi, statfs_buf
    syscall
    test rax, rax
    js .ud_done
    mov rax, [statfs_buf + 8] 
    mov rbx, [statfs_buf + 16] 
    mul rbx
    mov r13, rax
    mov rax, [statfs_buf + 8]
    mov rbx, [statfs_buf + 32] 
    mul rbx
    mov r14, rax
    mov r15, r13
    sub r15, r14
    mov rdi, [vp_disk]
    mov rsi, 2
    mov rdx, 1
    mov rcx, lbl_total
    call _viewport_write
    mov rax, r13
    shr rax, 30
    mov rdi, num_buf
    call _int_to_str
    mov rdi, [vp_disk]
    mov rsi, 10
    mov rdx, 1
    mov rcx, num_buf
    call _viewport_write
    mov rdi, [vp_disk]
    mov rsi, 15
    mov rdx, 1
    mov rcx, fmt_gb
    call _viewport_write
    mov rdi, [vp_disk]
    mov rsi, 2
    mov rdx, 2
    mov rcx, lbl_used
    call _viewport_write
    mov rax, r15
    shr rax, 30
    mov rdi, num_buf
    call _int_to_str
    mov rdi, [vp_disk]
    mov rsi, 10
    mov rdx, 2
    mov rcx, num_buf
    call _viewport_write
    mov rdi, [vp_disk]
    mov rsi, 15
    mov rdx, 2
    mov rcx, fmt_gb
    call _viewport_write
.ud_done: @restore_context
    ret

skip_spaces:
.ssl: mov al, [rsi]
    test al, al
    jz .ssd
    cmp al, ' '
    jne .ssd
    inc rsi
    jmp .ssl
.ssd: ret

skip_to_number:
.stnl: mov al, [rsi]
    test al, al
    jz .stnd
    cmp al, '0'
    jb .stnn
    cmp al, '9'
    jbe .stnd
.stnn: inc rsi
    jmp .stnl
.stnd: ret

parse_long:
.plsn: movzx rcx, byte [rsi]
    test rcx, rcx
    jz .pld
    cmp rcx, '0'
    jb .pln
    cmp rcx, '9'
    ja .pln
    jmp .plsp
.pln: inc rsi
    jmp .plsn
.plsp: xor rax, rax
.pll: movzx rcx, byte [rsi]
    cmp rcx, '0'
    jb .pld
    cmp rcx, '9'
    ja .pld
    sub rcx, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .pll
.pld: ret
