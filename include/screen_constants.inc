; screen_constants.inc - Viewport Structure Offsets and Flags
%ifndef SCREEN_CONSTANTS_INC
    %define SCREEN_CONSTANTS_INC

; Viewport Structuur Offsets
%define VP_X        0
%define VP_Y        8
%define VP_W        16
%define VP_H        24
%define VP_BUF      32
%define VP_BUF_H    40
%define VP_VIEW_Y   48
%define VP_FG       56
%define VP_BG       57
%define VP_FLAGS    58
%define VP_SIZE     64

; Viewport Flags
%define VPF_BORDER  1

%endif
