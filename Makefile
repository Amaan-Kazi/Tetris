all: Tetris

Tetris: src/main.asm
	mkdir -p build
	nasm -f elf64 src/main.asm -o build/main.o
	ld build/main.o -o build/Tetris

clean:
	rm -rf build
