# Makefile for Gemini Modules Tests

# Tools
ASM = nasm
LD  = ld

# Flags
ASM_FLAGS = -f elf64 -Iinclude/
LD_FLAGS  =

# Directories
SRC_DIR  = src
TEST_DIR = tests
OBJ_DIR  = build
INC_DIR  = include

# Modules (all compiled objects needed for linking)
ALL_MODULES = $(OBJ_DIR)/io.o $(OBJ_DIR)/string.o $(OBJ_DIR)/file.o $(OBJ_DIR)/cursor.o $(OBJ_DIR)/screen.o

# Tests
TESTS = test_io test_io_v2 test_string test_file

# Targets
.PHONY: all clean $(TESTS) run_tests

all: $(TESTS)

# Create build directory
$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

# Compile Modules from src/
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm | $(OBJ_DIR)
	$(ASM) $(ASM_FLAGS) $< -o $@

# General rule to link tests with all modules
$(OBJ_DIR)/test_%: $(TEST_DIR)/test_%.asm $(ALL_MODULES)
	$(ASM) $(ASM_FLAGS) $< -o $(OBJ_DIR)/test_$*.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/test_$*.o $(ALL_MODULES) -o $@

# Individual test targets
test_io: $(OBJ_DIR)/test_io
	./$(OBJ_DIR)/test_io

test_io_v2: $(OBJ_DIR)/test_io_v2
	./$(OBJ_DIR)/test_io_v2

test_string: $(OBJ_DIR)/test_string
	./$(OBJ_DIR)/test_string

test_file: $(OBJ_DIR)/test_file
	./$(OBJ_DIR)/test_file

# Run all tests
run_tests: $(TESTS)

clean:
	rm -rf $(OBJ_DIR)
