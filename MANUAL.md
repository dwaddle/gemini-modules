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

---

## 1. Algemeen & Systeem
*Gevestigd in `include/algemeen.mac` en `include/system.mac`*

### `@save_callee_saved` / `@restore_callee_saved`
Slaat alleen de registers op die volgens de System V ABI behouden moeten blijven (`RBX`, `RBP`, `R12-R15`). Veel efficiënter dan de oude context-save.

### `@get_argc stack_ptr`
Haalt het aantal command-line argumenten op. `stack_ptr` moet de waarde van `RSP` zijn bij de start van het programma.
- **Returns**: `RAX` bevat `argc`.

### `@get_argv stack_ptr, index`
Haalt de pointer naar een specifiek command-line argument op.
- **Returns**: `RAX` bevat de string pointer (of 0 bij ongeldige index).

### `@exit code`
Beëindigt het programma direct via syscall 60.

---

## 2. Cursor & Terminal Controle
*Gevestigd in `include/cursor_v2.mac`*

### `@goto_xy row, col`
Verplaatst de cursor naar een absolute positie (1-based).

### `@cursor_hide` / `@cursor_show`
Verbergt of toont de cursor voor een rustiger beeld tijdens updates.

---

## 3. Geheugenbeheer
*Gevestigd in `include/memory.mac`*

### `@mem_alloc size`
Reserveert geheugen. Gebruikt automatisch `mmap` voor grote blokken (>4KB) en de heap voor kleine blokken voor optimale stabiliteit.
- **Returns**: `RAX` = pointer naar geheugen.

### `@mem_free ptr`
Geeft geheugen vrij. Herkent automatisch of het een `mmap` of heap-allocatie was.

---

## 4. String Manipulatie
*Gevestigd in `include/string.mac`*

### `@strlen str_ptr`
**SIMD Geoptimaliseerd**. Berekent de lengte van een string met SSE 4.2 (verwerkt 16 bytes per cyclus).

### `@str_upper str_ptr` / `@str_lower str_ptr`
Converteert een string in-place naar hoofdletters of kleine letters.

---

## 7. Scherm & Viewports
*Gevestigd in `include/screen.mac`*

### `@screen_flip`
**Double Buffering**. Stuurt de volledige back-buffer naar de terminal. Gebruik dit na het renderen van je viewports om flickering te voorkomen.

### `@vp_create x, y, w, h, buf_h`
Maakt een viewport aan.

### `@vp_write vp_ptr, x, y, str_ptr`
Schrijft tekst naar de buffer op lokale coördinaten.

### `@vp_write_aligned vp_ptr, y, str_ptr, mode`
Schrijft tekst met uitlijning: `ALIGN_LEFT`, `ALIGN_CENTER` of `ALIGN_RIGHT`.

### `@vp_scroll vp_ptr, delta`
Scrollt de inhoud van een viewport omhoog (negatief) of omlaag (positief).

### `@vp_set_autoscroll vp_ptr, state`
Zet 1 om automatisch naar de nieuwste tekst te scrollen bij het schrijven.

### `@vp_set_border_color vp_ptr, fg, bg`
Stelt de kleur van de border in, handig voor focus-indicatie.

---

## 8. Debugging Tools
*Gevestigd in `include/debug.mac`*

### `@dump_regs`
Toont de inhoud van alle 64-bit registers.

### `@hex_dump ptr, len`
Genereert een geformatteerde hexadecimale dump van een geheugenregio, inclusief ASCII-weergave.

---

## 9. Wiskunde & Getallen
*Gevestigd in `include/math.mac`*

### `@rand`
Genereert een 64-bit pseudorandom getal via het Xorshift64 algoritme.
- **Returns**: `RAX` = random waarde.

### `@rand_seed value`
Initialiseert de random generator met een startwaarde.

---

## 10. Data Structuren
*Gevestigd in `include/list.mac`*

### `@list_push_front head_ptr, data` / `@list_push_back head_ptr, data`
Voegt een 64-bit waarde toe aan een enkelvoudig verbonden lijst. Gebruikt intern de snelle **SLAB allocator** voor nodes.

### `@list_pop_front head_ptr`
Haalt de eerste waarde uit de lijst en geeft de node terug aan de pool.

---

## 11. Security & Encoding
*Gevestigd in `include/security.mac`*

### `@base64_encode dest, src, len`
Zet binaire data om naar een Base64-geëncodeerde string.
