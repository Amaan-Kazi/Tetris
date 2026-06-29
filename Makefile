DETECTED_OS := Other
FIND_CMD    := find

ifeq ($(OS),Windows_NT)
	DETECTED_OS := Windows
	FIND_CMD    := /usr/bin/find
endif


# Directories
SRC_DIR   := src
BUILD_DIR := build

# Find all .asm files
SRCS := $(shell $(FIND_CMD) $(SRC_DIR) -name "*.asm")

# Platform specific object files [src/*.asm -> build/{platform}/*.o]
LINUX_OBJS   := $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/linux/%.o,$(SRCS))
WINDOWS_OBJS := $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/windows/%.obj,$(SRCS))

# Platform specific dependency files [src/*.asm -> build/{platform}/*.d]
LINUX_DEPS   := $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/linux/%.d,$(SRCS))
WINDOWS_DEPS := $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/windows/%.d,$(SRCS))


## Final Targets ##

.PHONY: all linux windows clean
all: linux windows

linux: $(BUILD_DIR)/linux/tetris
windows: $(BUILD_DIR)/windows/tetris.exe

clean:
	rm -rf $(BUILD_DIR)


## Compiling ##

$(BUILD_DIR)/linux/%.o: $(SRC_DIR)/%.asm
	mkdir -p $(dir $@)
	nasm -DPLATFORM_LINUX -f elf64 -MD $(patsubst %.o,%.d,$@) $< -o $@

$(BUILD_DIR)/windows/%.obj: $(SRC_DIR)/%.asm
	mkdir -p $(dir $@)
	nasm -DPLATFORM_WINDOWS -f win64 -MD $(patsubst %.obj,%.d,$@) $< -o $@


## Linking ##

LINKER_FLAGS         := -nostdlib -nodefaultlibs -nostartfiles -pie -Wl,-e,_start
WINDOWS_LINKER_FLAGS := -nostdlib -nodefaultlibs -nostartfiles -Wl,--dynamicbase,--nxcompat,-e,_start

$(BUILD_DIR)/linux/tetris: $(LINUX_OBJS)
	gcc $(LINKER_FLAGS) $(LINUX_OBJS) -o $@

$(BUILD_DIR)/windows/tetris.exe: $(WINDOWS_OBJS)
ifeq ($(DETECTED_OS),Windows)
	gcc $(WINDOWS_LINKER_FLAGS) $(WINDOWS_OBJS) -lkernel32 -o $@
else
	x86_64-w64-mingw32ucrt-gcc $(WINDOWS_LINKER_FLAGS) $(WINDOWS_OBJS) -lkernel32 -o $@
endif


# Include .d Makefiles
-include $(LINUX_DEPS)
-include $(WINDOWS_DEPS)

