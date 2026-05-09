# Makefile for gtop sample
ASM = nasm
LD  = ld

# Paths
ROOT_DIR = ../..
INC_DIR  = $(ROOT_DIR)/include
SRC_DIR  = $(ROOT_DIR)/src
BUILD_DIR = $(ROOT_DIR)/build

# Flags
ASM_FLAGS = -f elf64 -I$(INC_DIR)/ -w-dup
LD_FLAGS  =

# Modules required
MODULE_OBJS = $(BUILD_DIR)/screen.o \
              $(BUILD_DIR)/io.o \
              $(BUILD_DIR)/string.o \
              $(BUILD_DIR)/file.o \
              $(BUILD_DIR)/cursor.o \
              $(BUILD_DIR)/memory.o

TARGET = gtop

.PHONY: all clean run

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Ensure modules are built
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm
	$(ASM) $(ASM_FLAGS) $< -o $@

$(TARGET): gtop.asm $(MODULE_OBJS)
	$(ASM) $(ASM_FLAGS) gtop.asm -o gtop.o
	$(LD) $(LD_FLAGS) gtop.o $(MODULE_OBJS) -o $(TARGET)

run: all
	./$(TARGET)

clean:
	rm -f gtop.o $(TARGET)
