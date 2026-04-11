; network_constants.inc - Socket and Protocol Constants
%ifndef NETWORK_CONSTANTS_INC
    %define NETWORK_CONSTANTS_INC

; Address Families
%define AF_INET         2       ; IPv4 Internet protocols

; Socket Types
%define SOCK_STREAM     1       ; TCP
%define SOCK_DGRAM      2       ; UDP

; Protocols
%define IPPROTO_TCP     6
%define IPPROTO_UDP     17

; Struct sockaddr_in (16 bytes)
; offset 0: sin_family (word)
; offset 2: sin_port (word, big-endian)
; offset 4: sin_addr (dword)
; offset 8: sin_zero (8 bytes padding)
STR_SOCKADDR_IN_SIZE    equ 16

%endif
