; fileio_constants.inc - Systeemconstanten voor File I/O (x86_64 Linux)

; --- [ Open Flags ] ---
; Bepaalt hoe een bestand geopend moet worden (RSI register bij SYS_OPEN)
%define O_RDONLY    0        ; Alleen lezen
%define O_WRONLY    1        ; Alleen schrijven
%define O_RDWR      2        ; Lezen en schrijven
%define O_CREAT     64       ; Maak bestand aan als het niet bestaat
%define O_EXCL      128      ; Fout als O_CREAT wordt gebruikt en bestand bestaat al
%define O_TRUNC     512      ; Maak bestand leeg bij openen
%define O_APPEND    1024     ; Schrijf data aan het einde van het bestand

; --- [ File Permissions (Mode) ] ---
; Gebruikt wanneer O_CREAT actief is (RDX register bij SYS_OPEN)
; De 'q' suffix staat voor Octaal, de standaard voor Linux permissies
%define S_IRUSR     00400q   ; Eigenaar: Lezen
%define S_IWUSR     00200q   ; Eigenaar: Schrijven
%define S_IXUSR     00100q   ; Eigenaar: Uitvoeren
%define S_IRGRP     00040q   ; Groep: Lezen
%define S_IROTH     00004q   ; Anderen: Lezen

; Veelgebruikte combinaties
%define RW_USER     00600q   ; Eigenaar: Lezen & Schrijven
%define RW_ALL      00644q   ; Eigenaar: RW, Groep/Anderen: R (Standaard Linux)

; --- [ Seek Positions ] ---
; Gebruikt voor de 'whence' parameter in SYS_LSEEK
%define SEEK_SET    0        ; Vanaf het begin van het bestand
%define SEEK_CUR    1        ; Vanaf de huidige positie
%define SEEK_END    2        ; Vanaf het einde van het bestand

; --- [ Standard File Descriptors ] ---
%define STDIN       0
%define STDOUT      1
%define STDERR      2

; --- [ Access Modes ] ---
%define F_OK        0        ; Test of bestand bestaat