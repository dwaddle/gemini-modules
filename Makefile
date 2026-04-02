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

# Modules
MODULES = io.o string.o file.o cursor.o screen.o

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

# Compile and Link Tests
test_io: $(OBJ_DIR)/test_io
	./$(OBJ_DIR)/test_io

$(OBJ_DIR)/test_io: $(TEST_DIR)/test_io.asm $(OBJ_DIR)/io.o
	$(ASM) $(ASM_FLAGS) $(TEST_DIR)/test_io.asm -o $(OBJ_DIR)/test_io.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/test_io.o $(OBJ_DIR)/io.o -o $@

test_io_v2: $(OBJ_DIR)/test_io_v2
	./$(OBJ_DIR)/test_io_v2

$(OBJ_DIR)/test_io_v2: $(TEST_DIR)/test_io_v2.asm $(OBJ_DIR)/io.o $(OBJ_DIR)/string.o $(OBJ_DIR)/cursor.o $(OBJ_DIR)/screen.o
	$(ASM) $(ASM_FLAGS) $(TEST_DIR)/test_io_v2.asm -o $(OBJ_DIR)/test_io_v2.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/test_io_v2.o $(OBJ_DIR)/io.o $(OBJ_DIR)/string.o $(OBJ_DIR)/cursor.o $(OBJ_DIR)/screen.o -o $@

test_string: $(OBJ_DIR)/test_string
	./$(OBJ_DIR)/test_string

$(OBJ_DIR)/test_string: $(TEST_DIR)/test_string.asm $(OBJ_DIR)/string.o $(OBJ_DIR)/io.o $(OBJ_DIR)/screen.o
	$(ASM) $(ASM_FLAGS) $(TEST_DIR)/test_string.asm -o $(OBJ_DIR)/test_string.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/test_string.o $(OBJ_DIR)/string.o $(OBJ_DIR)/io.o $(OBJ_DIR)/screen.o -o $@

test_file: $(OBJ_DIR)/test_file
	./$(OBJ_DIR)/test_file

$(OBJ_DIR)/test_file: $(TEST_DIR)/test_file.asm $(OBJ_DIR)/file.o $(OBJ_DIR)/io.o $(OBJ_DIR)/string.o $(OBJ_DIR)/screen.o
	$(ASM) $(ASM_FLAGS) $(TEST_DIR)/test_file.asm -o $(OBJ_DIR)/test_file.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/test_file.o $(OBJ_DIR)/file.o $(OBJ_DIR)/io.o $(OBJ_DIR)/string.o $(OBJ_DIR)/screen.o -o $@

# Run all tests
run_tests: $(TESTS)

clean:
	rm -rf $(OBJ_DIR)
