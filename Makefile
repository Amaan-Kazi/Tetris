# Find all .asm files
SRC := $(shell find src -name "*.asm")

# Convert src/foo.asm → build/foo.o
OBJ := $(patsubst src/%.asm, build/%.o, $(SRC))

# Final binary
TARGET := build/Tetris

all: $(TARGET)

# Link everything
$(TARGET): $(OBJ)
	mkdir -p build
	ld $(OBJ) -o $(TARGET)

# Compile each .asm → .o (preserve structure)
build/%.o: src/%.asm
	mkdir -p $(dir $@)
	nasm -f elf64 $< -o $@

clean:
	rm -rf build

