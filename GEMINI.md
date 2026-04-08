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
- [ ] **`_mem_free` Implementation**: Real heap tracking for dynamic memory.
- [ ] **Viewport Titles**: Display labels in the top border of windows.
- [ ] **SIMD Optimization**: Use SSE/AVX for faster memory and string ops.
- [ ] **Register Dumper**: Macro to print all registers for debugging.

### 🖥 UI & Interaction
- [ ] **Raw Mode Toggle**: Catch arrow keys and special keys instantly.
- [ ] **Word Wrap**: Automatically wrap text within viewports.
- [ ] **Input Box Widget**: Reusable UI component for text entry.
- [ ] **Mouse Support**: ANSI sequence handling for mouse events.

### 🌐 Networking & System
- [ ] **CLI Argument Parser**: Helper for argc/argv processing.
- [ ] **Process Module**: Executing external commands and reading ENV vars.
- [ ] **Socket Module**: TCP client basics (connect, send, recv).

### 📂 Data Structures
- [ ] **Linked Lists**: Dynamic list management functions.
- [ ] **Hex Dump**: Formatted memory dump for debugging.
