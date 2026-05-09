# Gemini Modules API Manual

Welkom bij de officiële handleiding voor het Gemini Modules Framework. Dit framework biedt een verzameling NASM-macro's voor x86_64 Linux die complexe systeemtaken vereenvoudigen tot een bijna "high-level" programmeerervaring.

---

## Inhoudsopgave
1. [Algemeen & Systeem](#1-algemeen--systeem)
2. [Cursor & Terminal Controle](#2-cursor--terminal-controle)
3. [Geheugenbeheer](#3-geheugenbeheer)
4. [String Manipulatie](#4-string-manipulatie)
5. [Bestandssysteem (I/O)](#5-bestandssysteem-io)
6. [Netwerk (Sockets)](#6-netwerk-sockets)
7. [Scherm & Viewports](#7-scherm--viewports)
8. [Debugging Tools](#8-debugging-tools)

---

## 1. Algemeen & Systeem
*Gevestigd in `include/algemeen.mac`*

### `@save_context`
Slaat de huidige staat van alle general-purpose registers (`RBX` tot `R15`) op de stack op. Handig aan het begin van een functie.
- **Geen parameters.**

### `@restore_context`
Herstelt de registers die eerder met `@save_context` zijn opgeslagen.
- **Geen parameters.**

### `@clear register`
Zet een register op nul op de meest efficiënte manier (`xor reg, reg`).
- **Parameter 1**: Het register dat gewist moet worden (bijv. `RAX`).

### `@exit code`
Beëindigt het programma en keert terug naar het OS met de opgegeven exit-code.
- **Parameter 1**: De exit-code (bijv. `0` voor succes).

---

## 2. Cursor & Terminal Controle
*Gevestigd in `include/cursor_v2.mac`*

### `@goto_xy row, col`
Verplaatst de cursor naar een absolute positie op het scherm.
- **Parameter 1**: Rij (Y).
- **Parameter 2**: Kolom (X).

### `@cursor_move dir, count`
Verplaatst de cursor relatief ten opzichte van de huidige positie.
- **Parameter 1**: Richting karakter ('A'=Omhoog, 'B'=Omlaag, 'C'=Rechts, 'D'=Links).
- **Parameter 2**: Aantal stappen.

### `@cursor_home`, `@cursor_save`, `@cursor_restore`
Hulpmiddelen voor cursor-beheer zonder parameters.

---

## 3. Geheugenbeheer
*Gevestigd in `include/memory.mac`*

### `@mem_alloc size`
Reserveert een blok geheugen op de heap.
- **Parameter 1**: Aantal bytes.
- **Returns**: `RAX` bevat de pointer naar het nieuwe geheugenblok.

### `@mem_free ptr`
Geeft een eerder gealloceerd blok geheugen vrij.
- **Parameter 1**: Pointer naar het blok.

### `@mem_copy dest, src, count`
Kopieert data van de ene geheugenlocatie naar de andere.
- **Parameter 1**: Bestemming pointer.
- **Parameter 2**: Bron pointer.
- **Parameter 3**: Aantal bytes.

### `@mem_set dest, value, count`
Vult een blok geheugen met een specifieke byte-waarde.
- **Parameter 1**: Bestemming pointer.
- **Parameter 2**: Waarde (byte).
- **Parameter 3**: Aantal bytes.

---

## 4. String Manipulatie
*Gevestigd in `include/string.mac`*

### `@str_cmp str1, str2`
Vergelijkt twee null-terminated strings.
- **Returns**: `RAX` is 0 als ze gelijk zijn.

### `@str_copy dest, src`
Kopieert een null-terminated string van bron naar bestemming.

### `@str_to_int str_ptr`
Converteert een numerieke string naar een 64-bit integer.
- **Returns**: `RAX` bevat de integer waarde.

### `@int_to_str value, buffer`
Converteert een 64-bit integer naar een null-terminated string.
- **Parameter 1**: De waarde (register of immediate).
- **Parameter 2**: Pointer naar een buffer (minimaal 21 bytes).

---

## 5. Bestandssysteem (I/O)
*Gevestigd in `include/file.mac`*

### `@f_open_read filename` / `@f_open_write filename`
Opent een bestand voor respectievelijk lezen of schrijven (truncates existing).
- **Returns**: `RAX` bevat de File Descriptor (FD).

### `@f_read fd, buffer, count` / `@f_write fd, buffer, count`
Leest van of schrijft naar een geopende file descriptor.

### `@f_exists filename`
Controleert of een bestand bestaat.
- **Returns**: `RAX` is 1 indien aanwezig, anders 0.

---

## 6. Netwerk (Sockets)
*Gevestigd in `include/network.mac`*

### `@net_socket`
Maakt een nieuwe TCP socket aan.
- **Returns**: `RAX` bevat de Socket FD.

### `@net_connect fd, sockaddr_ptr`
Maakt verbinding met een externe host.
- **Parameter 2**: Pointer naar een `sockaddr_in` structuur.

### `@net_send fd, buffer, length` / `@net_recv fd, buffer, length`
Versturen en ontvangen van data over een socket.

---

## 7. Scherm & Viewports
*Gevestigd in `include/screen.mac`*

### `@cls`
Wist het volledige terminalscherm.

### `@vp_create x, y, w, h, buf_h`
Maakt een nieuw viewport object aan.
- **x, y**: Startpositie op het scherm.
- **w, h**: Zichtbare dimensies.
- **buf_h**: Hoogte van de interne scrollback buffer.
- **Returns**: `RAX` bevat de pointer naar de Viewport struct.

### `@vp_write vp_ptr, x, y, str_ptr`
Schrijft tekst in de buffer van de viewport op een relatieve positie.

### `@vp_render vp_ptr`
Tekent de viewport en zijn inhoud daadwerkelijk op het terminalscherm.

---

## 8. Debugging Tools
*Gevestigd in `include/debug.mac`*

### `@dump_regs`
Een krachtige macro die de huidige staat van **alle** registers (inclusief vlaggen) naar de terminal print in een leesbaar formaat. Bewaart de context van het programma volledig.
