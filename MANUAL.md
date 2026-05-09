# Professional ASM Modules API Manual

Welkom bij de officiële handleiding voor het Professional ASM Modules Framework. Dit framework biedt een verzameling NASM-macro's voor x86_64 Linux die complexe systeemtaken vereenvoudigen tot een bijna "high-level" programmeerervaring.

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
9. [Wiskunde & Getallen](#9-wiskunde--getallen)
10. [Data Structuren](#10-data-structuren)
11. [Security & Encoding](#11-security--encoding)
12. [Seriële Communicatie](#12-seriële-communicatie)

---

## 1. Algemeen & Systeem
*Gevestigd in `include/algemeen.mac` en `include/system.mac`*

### `@save_callee_saved` / `@restore_callee_saved`
Slaat alleen de registers op die volgens de System V ABI behouden moeten blijven (`RBX`, `RBP`, `R12-R15`). Dit is de professionele standaard voor functie-aanroepen.
- **Gebruik**: Aan het begin en einde van je functies om registers van de beller te beschermen.

### `@get_argc stack_ptr`
Haalt het aantal command-line argumenten op.
- **stack_ptr**: Moet de waarde van `RSP` zijn bij de start van het programma.
- **Returns**: `RAX` bevat `argc`.

### `@get_argv stack_ptr, index`
Haalt de pointer naar een specifiek command-line argument op.
- **index**: 0 is de programmanaam, 1 is het eerste argument, etc.
- **Returns**: `RAX` bevat de string pointer (of 0 bij ongeldige index).

### `@exit code`
Beëindigt het programma direct via syscall 60.
- **code**: De return waarde naar de shell (bijv. 0 voor succes).

---

## 2. Cursor & Terminal Controle
*Gevestigd in `include/cursor_v2.mac`*

### `@goto_xy row, col`
Verplaatst de cursor naar een absolute positie (1-based).
- **row**: Rij (Y-as).
- **col**: Kolom (X-as).

### `@cursor_hide` / `@cursor_show`
Maakt de cursor onzichtbaar of weer zichtbaar. Handig voor vloeiende UI updates.

### `@cursor_save` / `@cursor_restore`
Slaat de huidige cursorpositie op in de terminal-buffer en herstelt deze later.

---

## 3. Geheugenbeheer
*Gevestigd in `include/memory.mac`*

### `@mem_alloc size`
Reserveert geheugen. Gebruikt automatisch `mmap` voor grote blokken (>4KB) voor maximale stabiliteit en de heap voor kleine blokken.
- **Returns**: `RAX` = pointer naar geheugen.

### `@mem_free ptr`
Geeft geheugen vrij. Herkent automatisch het type allocatie en handelt dit correct af.

### `@mem_copy dest, src, count`
Kopieert `count` bytes van `src` naar `dest`. Zeer efficiënt via `rep movsb`.

### `@mem_set dest, value, count`
Vult een geheugenregio met een specifieke byte waarde.

---

## 4. String Manipulatie
*Gevestigd in `include/string.mac`*

### `@strlen str_ptr`
**SIMD Geoptimaliseerd**. Berekent de lengte van een string met SSE 4.2 (verwerkt 16 bytes per cyclus).
- **Returns**: `RAX` = lengte.

### `@str_cmp str1, str2`
Vergelijkt twee strings.
- **Returns**: `RAX` is 0 indien identiek.

### `@str_copy dest, src`
Kopieert de string van `src` naar `dest` (inclusief null-terminator).

### `@str_cat base, extra`
Voegt `extra` toe aan het einde van `base`. Zorg voor voldoende bufferruimte!

### `@str_find haystack, needle`
Zoekt naar `needle` binnen `haystack`.
- **Returns**: `RAX` = pointer naar start van de match, of 0.

### `@str_upper str_ptr` / `@str_lower str_ptr`
Converteert een string in-place naar hoofdletters of kleine letters.

### `@str_rev str_ptr`
Draait de volgorde van de karakters in een string om (in-place).

### `@str_to_int str_ptr`
Converteert een numerieke string naar een 64-bit integer in `RAX`.

### `@int_to_str value, buffer`
Zet een integer om naar een string in de opgegeven buffer.

---

## 5. Bestandssysteem (I/O)
*Gevestigd in `include/file.mac`*

### `@f_open_read filename` / `@f_open_write filename`
Opent een bestand voor lezen of (over)schrijven.
- **Returns**: `RAX` = File Descriptor (FD), of negatief bij fout.

### `@f_read fd, buffer, count` / `@f_write fd, buffer, count`
Leest of schrijft binaire data van/naar een bestand.

### `@f_seek fd, offset, whence`
Verplaatst de vijl-pointer. `whence`: 0=SET, 1=CUR, 2=END.

### `@f_exists filename`
Controleert of een bestand aanwezig is.
- **Returns**: `RAX` = 1 (ja) of 0 (nee).

---

## 6. Netwerk (Sockets)
*Gevestigd in `include/network.mac`*

### `@net_socket`
Maakt een nieuwe TCP socket aan. `RAX` = FD.

### `@net_bind fd, sockaddr_ptr` / `@net_listen fd, backlog`
Server-side: bindt een socket aan een adres en begint te luisteren.

### `@net_accept fd, sockaddr_out, addrlen_ptr`
Wacht op een inkomende verbinding. `RAX` = Client FD.

### `@net_connect fd, sockaddr_ptr`
Client-side: verbindt met een server.

### `@net_send fd, buf, len` / `@net_recv fd, buf, len`
Data versturen en ontvangen over een actieve verbinding.

---

## 7. Scherm & Viewports
*Gevestigd in `include/screen.mac`*

### `@screen_flip`
**Double Buffering Engine**. Kopieert de volledige back-buffer in één keer naar de terminal. Onmisbaar voor professionele, flikkervrije TUI's.

### `@vp_create x, y, w, h, buf_h`
Maakt een viewport aan. `buf_h` is de hoogte van de interne buffer voor scrollen.

### `@vp_write vp_ptr, x, y, str_ptr`
Schrijft tekst naar de viewport op lokale coördinaten.

### `@vp_write_aligned vp_ptr, y, str_ptr, mode`
Schrijft tekst met uitlijning: `ALIGN_LEFT`, `ALIGN_CENTER` of `ALIGN_RIGHT`.

### `@vp_scroll vp_ptr, delta`
Scrollt de inhoud (positief = omlaag naar nieuwe tekst, negatief = omhoog naar historie).

### `@vp_set_autoscroll vp_ptr, state`
Indien 1, scrollt de viewport automatisch naar de laatste regel bij elke schrijfactie.

---

## 8. Debugging Tools
*Gevestigd in `include/debug.mac`*

### `@dump_regs`
Print de huidige waarde van alle registers naar het scherm.

### `@hex_dump ptr, len`
Genereert een professionele hex-dump van een geheugenregio inclusief ASCII kolom.

---

## 9. Wiskunde & Getallen
*Gevestigd in `include/math.mac`*

### `@rand`
Genereert een 64-bit pseudorandom getal (Xorshift64).

### `@rand_seed value`
Initialiseert de random generator.

---

## 10. Data Structuren
*Gevestigd in `include/list.mac`*

### `@list_push_front head_ptr, data` / `@list_push_back head_ptr, data`
Voegt een waarde toe aan een Linked List. Gebruikt de supersnelle **SLAB allocator**.

### `@list_pop_front head_ptr`
Haalt de eerste waarde uit de lijst.

---

## 11. Security & Encoding
*Gevestigd in `include/security.mac`*

### `@base64_encode dest, src, len`
Zet binaire data om naar Base64 tekst.

---

## 12. Seriële Communicatie
*Gevestigd in `include/macros.inc`*

### `@serial_open device_path`
Opent een seriële poort (bijv. `/dev/ttyS0`).

### `@serial_config fd, baudrate`
Configureert de poort met de opgegeven snelheid (bijv. `B9600`).
