# Gemini Modules Macro API Reference

A high-level assembly framework for x86_64 Linux, providing a "higher-level language" experience through NASM macros.

---

## 🚀 Quick Start Example
Here is a minimal program using the Gemini library:

```nasm
%include "algemeen.mac"
%include "screen.mac"

section .data
    msg db "Hello, Gemini Viewports!", 0

section .text
    global _start

_start:
    @cls                            ; Clear screen
    @vp_create 5, 5, 30, 10, 50     ; Create viewport at (5,5), size 30x10, buffer 50
    mov r12, rax                    ; Save viewport pointer in R12
    
    @vp_set_border r12, 1           ; Enable border
    @vp_set_color  r12, 2, 0        ; Green on Black
    
    @vp_write r12, 2, 2, msg        ; Write message at local (2,2)
    @vp_render r12                  ; Draw to screen
    
    @exit 0
```

---

## 1. Viewport & Screen Control
*Located in `include/screen.mac` and `include/cursor_v2.mac`.*

### `@vp_create x, y, w, h, buf_h`
Creates an independent window on the screen.
- **x, y**: Physical screen coordinates (top-left corner).
- **w, h**: Visible width and height on the screen.
- **buf_h**: Total scrollback capacity (number of lines kept in memory).
- **Returns**: `RAX` contains the pointer to the Viewport structure.

### `@vp_write vp_ptr, x, y, str_ptr`
Writes a null-terminated string into the viewport's private buffer.
- **vp_ptr**: Pointer returned by `@vp_create`.
- **x, y**: Coordinates *relative* to the viewport's top-left corner.
- **str_ptr**: Memory address of the string to write.

### `@vp_set_color vp_ptr, fg, bg`
Sets the text and background color for the specified viewport.
- **Color Codes**: 0:Black, 1:Red, 2:Green, 3:Yellow, 4:Blue, 5:Magenta, 6:Cyan, 7:White.

### `@vp_scroll vp_ptr, lines`
Moves the visible area of the buffer.
- **lines**: Positive value scrolls down (new lines appear), negative value scrolls up (history appears).

---

## 2. String Manipulation
*Located in `include/string.mac`.*

### `@str_to_int str_ptr`
Parses a numeric string and returns its value.
- **Returns**: `RAX` = the integer value. Stops at first non-numeric character.

### `@int_to_str value, buffer`
Converts a 64-bit integer into a null-terminated string.
- **value**: Register or immediate value to convert.
- **buffer**: Destination memory (should be at least 21 bytes for 64-bit MAX_INT).

### `@str_upper str_ptr` / `@str_lower str_ptr`
Converts the casing of a string **in-place**. This modifies the original data.

---

## 3. Memory Management
*Located in `include/memory.mac`.*

### `@mem_alloc size`
Reserves a block of dynamic memory on the heap.
- **size**: Number of bytes requested.
- **Returns**: `RAX` = pointer to the new block, or 0 if allocation failed.

### `@mem_copy dest, src, count`
Highly optimized block copy using CPU `rep movsb` instruction.
- **count**: Number of bytes to copy.

---

## 4. File System
*Located in `include/file.mac`.*

### `@f_open_write filename`
Opens a file for writing. If it doesn't exist, it is created. If it does, it is truncated.
- **Returns**: `RAX` = File Descriptor (FD).

### `@f_read fd, buffer, count`
Reads raw data from an open file.
- **Returns**: `RAX` = number of bytes actually read.

---

## Current Roadmap (TODO)

### 🛠 Core & Stability
- [x] **`_mem_free` Implementation**: Real heap tracking for dynamic memory.
- [x] **Viewport Titles**: Display labels in the top border of windows.
- [ ] **SIMD Optimization**: Use SSE/AVX for faster memory and string ops.
- [x] **Register Dumper**: Macro to print all registers for debugging.

### 🖥 UI & Interaction
- [x] **Raw Mode Toggle**: Catch arrow keys and special keys instantly.
- [ ] **Word Wrap**: Automatically wrap text within viewports.
- [ ] **Input Box Widget**: Reusable UI component for text entry.
- [ ] **Mouse Support**: ANSI sequence handling for mouse events.

### 🌐 Networking & System
- [ ] **CLI Argument Parser**: Helper for argc/argv processing.
- [x] **Process Module**: Executing external commands and reading ENV vars.
- [x] **Socket Module**: TCP client & server basics (connect, bind, listen, accept, send, recv).

### 🔌 Hardware & Serial
- [ ] **Serial Port I/O**: Read from RS-232/Serial devices with file-based mocking for testing.

### 📂 Data Structures
- [ ] **Linked Lists**: Dynamic list management functions.
- [ ] **Hash Maps**: Fast key-value lookups for system strings.
- [ ] **Circular Buffers**: High-performance I/O buffering.
- [ ] **Hex Dump**: Formatted memory dump for debugging.

### 🧵 Concurrency & Multitasking
- [ ] **Thread Wrapper**: Macros for `clone` or `pthread` style execution.
- [ ] **Mutex/Spinlock**: Basic synchronization primitives for shared memory.
- [ ] **Signal Handler**: Catch `SIGINT` (Ctrl+C) and `SIGWINCH` (Resize) gracefully.

### 📊 Data Parsing & Serialization
- [ ] **JSON Lite**: Basic parser for configuration files.
- [ ] **CSV Engine**: Fast processing of structured system data.
- [ ] **XML Parser**: Support for complex system descriptors.

### 🧮 Math & Logic
- [ ] **Fixed-point arithmetic**: For UI scaling without FPU overhead.
- [x] **Random Number Generator**: Macro for `/dev/urandom` and fast LCG.
- [ ] **Checksums**: CRC32 or Adler-32 implementation for data integrity.

### 🔐 Security & Encryption
- [ ] **SHA-256**: Native assembly hash implementation.
- [ ] **Base64**: Encoder and decoder for binary data.
- [ ] **Constant-time Compare**: Prevent timing attacks in string comparisons.

### 🕒 System & Diagnostics
- [ ] **Time Formatter**: Convert Unix timestamps to ISO strings.
- [ ] **Stack Tracer**: Basic backtrace on application panic.
- [ ] **Memory Watcher**: Track leaks and heap usage in debug mode.
- [ ] **Inotify Wrapper**: Monitor filesystem changes.
- [ ] **Epoll/Poll Support**: High-performance I/O for the socket module.
- [ ] **Logging Framework**: Level-based logging (INFO, DEBUG, ERROR) with file output.

### 🗜 Compression & Archiving
- [ ] **RLE Compression**: Simple Run-Length Encoding for buffer snapshots.
- [ ] **Zlib/Deflate**: Basic implementation for compressed network/file streams.

### 🌍 High-level Protocols
- [ ] **HTTP Client**: Basic GET/POST implementation for REST APIs.
- [ ] **DNS Resolver**: Pure ASM implementation to resolve hostnames.

### 📜 Configuration
- [ ] **INI Parser**: Read and write simple configuration files.
- [ ] **ENV Manager**: Easy access and manipulation of environment variables.

### 🔈 Media & Sound
- [ ] **ALSA Wrapper**: Basic PCM sound output for alerts and feedback.

### 🎨 Advanced UI & Visuals
- [ ] **Advanced TUI Widgets**: Modals, dropdowns, checkboxes, and radio buttons.
- [ ] **Live Memory/Stack Inspector**: Real-time hex-dump viewport for debugging.
- [ ] **High-Res Unicode Graphics**: Use Braille patterns and Block elements for 1/8th character precision.
- [ ] **Resource Bars**: Reusable horizontal/vertical bars for CPU, RAM, or progress metrics.
- [ ] **Off-screen Rendering**: Buffer viewport/screen content for atomic "flips" to avoid flickering.
- [ ] **Progress Bars**: Visual feedback widgets for long-running tasks.
- [ ] **Real-time Graphs**: High-resolution line and area charts using Braille patterns for smooth data visualization.
- [ ] **Layout Engine**: Automatic viewport positioning (Flexbox-style).
- [ ] **Color Themes**: Loadable CSS-like definitions for terminal colors.

---

## 📦 Complete Applicaties (Showcases)

### 🔗 Gemini Socat (`gsocat`)
Een krachtige "relay" tool die data bidirectioneel verplaatst tussen twee willekeurige endpoints.
- [ ] **Bi-directionele I/O Loop**: Gelijktijdig lezen en schrijven tussen twee file descriptors zonder blokkering.
- [ ] **Unified Address Parser**: Een parser die strings als `TCP-LISTEN:8080`, `FILE:test.txt`, of `SERIAL:/dev/ttyS0` omzet naar de juiste FD's.
- [ ] **I/O Multiplexing**: Implementatie van `select` of `epoll` om efficiënt op data van beide kanten te wachten.
- [ ] **Buffer Management**: Slimme ring-buffers om snelheidsverschillen tussen endpoints op te vangen.

### 📊 Gemini Top (`gtop`)
Een realtime process monitor die de prestaties van het systeem visualiseert.
- [ ] **Proc-FS Parser**: Uitlezen van CPU (totaal en per core), RAM en procesgegevens uit `/proc`.
- [ ] **Per-Core View**: Individuele belasting-balken voor elke core (gebruikmakend van de Resource Bar module).
- [ ] **Live History Graphs**: Hoge-resolutie CPU/RAM geschiedenis (gebruikmakend van de High-Res Graphics module).
- [ ] **System Dashboard**: Een responsieve layout die alle parsed data samenbrengt.

### 📝 Gemini Text Editor (`gedit`)
Een minimalistische terminal-gebaseerde tekstverwerker.
- [ ] **Buffer Management**: Efficiënt beheer van grote tekstbestanden in het geheugen.
- [ ] **Key-bind Engine**: Koppeling van toetsaanslagen aan acties (kopiëren, plakken, opslaan).

### 🕸️ Gemini Web Server (`ghttpd`)
Een krachtige statische webserver met een extreem lage voetafdruk.
- [ ] **HTTP Router**: Koppelen van URL's aan lokale bestanden.
- [ ] **Header Management**: Verzenden van correcte MIME-types en caching-headers.

### 💬 Gemini Chat Client (`gchat`)
Een terminal-gebaseerde chat-applicatie over TCP/IP.
- [ ] **Message Protocol**: Een lichtgewicht protocol voor berichtuitwisseling.
- [ ] **UI Sync**: Realtime bijwerken van het chat-venster terwijl de gebruiker typt.

### 💾 Gemini Database (`gdb`)
Een snelle key-value store voor data-persistentie.
- [ ] **B-Tree Engine**: On-disk indexing voor snelle lookups.
- [ ] **Transaction Log**: Garanderen van data-integriteit bij crashes.

### 🖼️ Gemini Image Viewer (`gview`)
Bekijk afbeeldingen direct in je terminal.
- [ ] **Sixel/Kitty Support**: Ondersteuning voor high-res rendering in de terminal.
- [ ] **BMP/Raw Parser**: Native image decoding in Assembly.

### 🕹️ Gemini Tetris (`gtris`)
Een klassieke Tetris-kloon gebouwd in Assembly.
- [ ] **Game Logic**: Pure ASM implementatie van de Tetris-mechanieken.
- [ ] **Sound Effects**: Gebruik van de ALSA-module voor retro audio feedback.
