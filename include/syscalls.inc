; syscalls.inc - Linux x86_64 System Call Numbers
%ifndef SYSCALLS_INC
    %define SYSCALLS_INC

%define SYS_READ      0
%define SYS_WRITE     1
%define SYS_OPEN      2
%define SYS_CLOSE     3
%define SYS_STAT      4
%define SYS_FSTAT     5
%define SYS_LSTAT     6
%define SYS_POLL      7
%define SYS_LSEEK     8
%define SYS_MMAP      9
%define SYS_MPROTECT  10
%define SYS_MUNMAP    11
%define SYS_BRK       12
%define SYS_ACCESS    21
%define SYS_RENAME    82
%define SYS_UNLINK    87
%define SYS_EXIT      60

%endif
