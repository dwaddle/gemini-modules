# Makefile for Gemini Modules Tests

# Tools
ASM = nasm
LD  = ld

# Flags
ASM_FLAGS = -f elf64 -Iinclude/ -w-dup
LD_FLAGS  =

# Directories
SRC_DIR  = src
TEST_DIR = tests
OBJ_DIR  = build
INC_DIR  = include

# Modules
ALL_MODULES = $(OBJ_DIR)/screen.o $(OBJ_DIR)/io.o $(OBJ_DIR)/string.o $(OBJ_DIR)/file.o $(OBJ_DIR)/cursor.o $(OBJ_DIR)/memory.o $(OBJ_DIR)/debug.o $(OBJ_DIR)/network.o

# Tests
TESTS = test_io test_io_v2 test_string test_file test_memory test_screen_buffer test_viewports test_screen_wrap test_debug test_io_color test_network

# Targets
.PHONY: all clean $(TESTS) run_tests dashboard

all: $(TESTS) dashboard

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

test_memory: $(OBJ_DIR)/test_memory
	./$(OBJ_DIR)/test_memory

test_screen_buffer: $(OBJ_DIR)/test_screen_buffer
	./$(OBJ_DIR)/test_screen_buffer

test_viewports: $(OBJ_DIR)/test_viewports
	./$(OBJ_DIR)/test_viewports

test_screen_wrap: $(OBJ_DIR)/test_screen_wrap
	./$(OBJ_DIR)/test_screen_wrap

# Sample target
dashboard: $(OBJ_DIR)/dashboard
	./$(OBJ_DIR)/dashboard

$(OBJ_DIR)/dashboard: samples/dashboard/dashboard.asm $(ALL_MODULES)
	$(ASM) $(ASM_FLAGS) samples/dashboard/dashboard.asm -o $(OBJ_DIR)/dashboard.o
	$(LD) $(LD_FLAGS) $(OBJ_DIR)/dashboard.o $(ALL_MODULES) -o $@

# Run all tests
run_tests: $(TESTS)

clean:
	rm -rf $(OBJ_DIR)
