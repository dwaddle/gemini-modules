; io_constants.inc - Termios and IO Constants
%ifndef IO_CONSTANTS_INC
    %define IO_CONSTANTS_INC

; Linux Termios Constants (x86_64)
%define TCGETS      0x5401
%define TCSETS      0x5402

; Baud Rates
%define B9600       0x0000000D
%define B115200     0x00001002

; Control Modes
%define CS8         0x00000030
%define CLOCAL      0x00000800
%define CREAD       0x00000080

; Local Modes
%define ICANON      0x00000002
%define ECHO        0x00000008

%endif
