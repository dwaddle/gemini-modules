; syscalls.inc - Linux x86_64 System Call Numbers
%ifndef SYSCALLS_INC
    %define SYSCALLS_INC

; File & Process Operations
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

; Networking Operations
%define SYS_SOCKET      41
%define SYS_CONNECT     42
%define SYS_ACCEPT      43
%define SYS_SENDTO      44
%define SYS_RECVFROM    45
%define SYS_SENDMSG     46
%define SYS_RECVMSG     47
%define SYS_SHUTDOWN    48
%define SYS_BIND        49
%define SYS_LISTEN      50
%define SYS_GETSOCKNAME 51
%define SYS_GETPEERNAME 52
%define SYS_SOCKETPAIR  53
%define SYS_SETSOCKOPT  54
%define SYS_GETSOCKOPT  55

%endif
