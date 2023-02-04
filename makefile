OS_NAME=tongseng
VERSION=0.1

CC=gcc
LD=ld
RM=/usr/bin/env rm -f

SRC_PATH=src
OBJ_PATH=obj
BIN_PATH=kernel
INC_PATHS=include

CFLAGS ?= -g -O2 -pipe -Wall -Wextra
NASMFLAGS ?= -F dwarf -g
LDFLAGS ?=

override CFLAGS +=       \
	-DVERSION=\"$(VERSION)\" \
	-Wall 					 \
    -std=c11             \
    -ffreestanding       \
    -fno-stack-protector \
    -fno-stack-check     \
    -fno-lto             \
    -fno-pie             \
    -fno-pic             \
    -m64                 \
    -march=x86-64        \
    -mabi=sysv           \
    -mno-80387           \
    -mno-mmx             \
    -mno-sse             \
    -mno-sse2            \
    -mno-red-zone        \
    -mcmodel=kernel      \
    -MMD

override LDFLAG+=\
	-nostdlib               \
    -static                 \
	-m elf_x86_64			\
    -z max-page-size=0x1000 \
    -T $(SRC_PATH)/linker.ld

NASMFLAGS=

INCLUDES=$(addprefix -I,$(INC_PATHS))
C_FILES=$(wildcard $(SRC_PATH)/*.c)
NASM_FILES=$(wildcard $(SRC_PATH)/*.asm)
ASF_FILES=$(wildcard $(SRC_PATH)/*.S)
OBJ_FILES=$(patsubst $(SRC_PATH)/%.c,$(OBJ_PATH)/%.o,$(C_FILES)) $(patsubst $(SRC_PATH)/%.asm,$(OBJ_PATH)/%.o,$(NASM_FILES)) $(patsubst $(SRC_PATH)/%.S,$(OBJ_PATH)/%.o,$(ASF_FILES))
DEP_FILES=$(patsubst $(SRC_PATH)/%.c,$(OBJ_PATH)/%.d,$(C_FILES))

.PHONY: all
all: mkdir $(BIN_PATH)/$(OS_NAME)

mkdir: $(OBJ_PATH) $(BIN_PATH)

$(OBJ_PATH):
	mkdir -p $(OBJ_PATH)

$(BIN_PATH):
	mkdir -p $(BIN_PATH) 

$(BIN_PATH)/$(OS_NAME): $(OBJ_FILES)
	$(LD) -o $@ $^ $(LDFLAG)

$(OBJ_PATH)/%.o: $(SRC_PATH)/%.c include/limine.h
	$(CC) -o $@ -c $< $(CFLAGS) -I$(SRC_PATH) $(INCLUDES)

$(OBJ_PATH)/%.o: $(SRC_PATH)/%.asm
	nasm $(NASMFLAGS) -o $@ $<

$(OBJ_PATH)/%.o: $(SRC_PATH)/%.S include/limine.h
	$(CC) -o $@ -c $< $(CFLAGS) -I$(SRC_PATH) $(INCLUDES)

-include $(DEP_FILES)

limine:
	git clone https://github.com/limine-bootloader/limine.git --branch=v4.x-branch-binary --depth=1
	make -C limine


barebones.iso: all limine
	$(RM) -r iso_mount
	mkdir -p iso_mount
	cp $(BIN_PATH)/$(OS_NAME) iso_mount
	cp limine.cfg iso_mount
	cp limine/limine.sys limine/limine-cd.bin limine/limine-cd-efi.bin iso_mount
	xorriso -as mkisofs -b limine-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-cd-efi.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		iso_mount -o $@
	limine/limine-deploy $@
	rm -rf iso_mount

.PHONY: run
run: barebones.iso
	qemu-system-x86_64 -M q35 -m 2G -cdrom barebones.iso -boot d

.PHONY: inc
include:
	mkdir -p include

include/limine.h: include
	curl https://raw.githubusercontent.com/limine-bootloader/limine/trunk/limine.h -o $@

.PHONY: clean
clean:
	rm -rf $(OBJ_PATH) $(BIN_PATH) $(INC_PATHS) barebones.iso

.PHONY: lsp
lsp: clean
	bear -- make all
