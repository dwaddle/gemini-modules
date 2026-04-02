# Gemini Modules Project Overview

This project is a collection of 64-bit NASM assembly modules and macros for Linux. It provides a foundation for assembly development by abstracting common tasks like string manipulation, file I/O, and terminal control.

## Project Structure

- **`src/` (Core Modules):**
    - `string.asm`: High-level string operations (compare, copy, find, trim, concat, case conversion, numeric validation, reverse, atoi/itoa).
    - `file.asm`: Advanced file system operations (open, close, read, write, size, exists, delete, rename, seek).
    - `io.asm`: Basic and advanced I/O (PrintString, PrintInt, PrintHex, PrintColor, ReadString, ReadChar).
    - `cursor.asm`: Dedicated cursor control (GotoXY, MoveRelative, Save/Restore).
    - `screen.asm`: Screen management (Clear, ResetColor, Hide/Show Cursor).
- **`include/` (Macros & Constants):**
    - Consolidates all `.mac` and `.inc` files for easy access.
    - `algemeen.mac`, `syscalls.inc`, `file_constants.inc`, etc.
- **`tests/`:**
    - Comprehensive unit tests for all modules. Use `make run_tests` to execute.
- **`samples/`:**
    - Real-world usage examples.

## Building and Running

The project includes a `Makefile` to simplify building, testing, and cleaning.

### 1. Run All Tests
```bash
make run_tests
```

### 2. Run Individual Tests
```bash
make test_io
make test_io_v2
make test_string
make test_file
```

### 3. Clean Build Artifacts
```bash
make clean
```

## Development Conventions

### Language & Architecture
- **Language:** NASM (Netwide Assembler)
- **Architecture:** x86_64
- **Platform:** Linux (utilizes Linux syscalls)

### Naming Conventions
- **Subroutines:** Publicly accessible functions typically start with an underscore (e.g., `_str_compare`) or use PascalCase.
- **Macros:** High-level macro wrappers start with an `@` symbol (e.g., `@str_cmp`, `@goto_xy`).

### Best Practices
- **Context Preservation:** Functions must use `@save_context` and `@restore_context` to ensure register stability for the caller.
- **Includes:** Use `-Iinclude/` during assembly to include the macro library.
