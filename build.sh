#!/usr/bin/env bash

# Created with Claude. Temp script, will be reworked

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$ROOT_DIR/build"
SRC_DIR="$ROOT_DIR/src"

NASM_BIN="${NASM_BIN:-nasm}"
QEMU_BIN="${QEMU_BIN:-qemu-system-i386}"
CC_CROSS="${CC_CROSS:-i386-elf-gcc}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [build|run|clean]

Targets:
  build  Assemble bootloader, create bootable image (build/boot.img). Optionally build kernel.o
  run    Launch QEMU with the built image
  clean  Remove build artifacts

Env overrides:
  NASM_BIN=/path/to/nasm
  QEMU_BIN=/path/to/qemu-system-i386
  CC_CROSS=/path/to/i386-elf-gcc
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' not found in PATH." >&2
    exit 1
  fi
}

build_bootloader() {
  require_cmd "$NASM_BIN"
  mkdir -p "$OUT_DIR"

  # Strip leading '//' lines (e.g., '// filepath: ...') so NASM doesn't choke.
  BOOT_ASM_IN="$SRC_DIR/boot/bootloader.asm"
  BOOT_ASM_PRE="$OUT_DIR/bootloader.pre.asm"
  BOOT_BIN="$OUT_DIR/bootloader.bin"
  BOOT_IMG="$OUT_DIR/boot.img"

  if [[ ! -f "$BOOT_ASM_IN" ]]; then
    echo "Error: bootloader source not found: $BOOT_ASM_IN" >&2
    exit 1
  fi

  # Remove lines starting with '//' to tolerate editor metadata comments.
  sed '/^[[:space:]]*\/\//d' "$BOOT_ASM_IN" > "$BOOT_ASM_PRE"

  # Assemble raw binary
  "$NASM_BIN" -f bin "$BOOT_ASM_PRE" -o "$BOOT_BIN"

  # Ensure at least 512 bytes and write boot signature 0x55AA at bytes 510–511
  # This keeps existing content and just forces the size/signature.
  dd if=/dev/zero of="$BOOT_BIN" bs=1 count=0 seek=512 2>/dev/null
  printf '\x55\xAA' | dd of="$BOOT_BIN" bs=1 seek=510 conv=notrunc 2>/dev/null

	# Create a 1.44MB floppy image and write our boot sector at LBA 0
	dd if=/dev/zero of="$BOOT_IMG" bs=512 count=2880 2>/dev/null
	dd if="$BOOT_BIN" of="$BOOT_IMG" bs=512 count=1 conv=notrunc 2>/dev/null

  # Ajout du kernel à partir du secteur 2 (LBA 1)
  KERNEL_BIN="$OUT_DIR/kernel.bin"
  if [[ -f "$KERNEL_BIN" ]]; then
    dd if="$KERNEL_BIN" of="$BOOT_IMG" bs=512 seek=1 conv=notrunc 2>/dev/null
    echo "Kernel ajouté à l'image disque à partir du secteur 2."
  else
    echo "Attention : kernel.bin introuvable, image disque sans kernel."
  fi

  echo "Built boot sector: $BOOT_BIN"
  echo "Bootable image:    $BOOT_IMG"
}

build_kernel() {
  # Detect compiler for 32-bit kernel
  if command -v i386-elf-gcc >/dev/null 2>&1; then
    CC=i386-elf-gcc
    LD=i386-elf-ld
    OBJCOPY=i386-elf-objcopy
    CFLAGS="-m32"
  elif command -v x86_64-elf-gcc >/dev/null 2>&1; then
    CC=x86_64-elf-gcc
    LD=x86_64-elf-ld
    OBJCOPY=x86_64-elf-objcopy
    CFLAGS="-m32"
  elif command -v gcc >/dev/null 2>&1; then
    CC=gcc
    LD=ld
    OBJCOPY=objcopy
    CFLAGS="-m32"
    echo "Info: using system gcc with -m32 for 32-bit kernel build."
  else
    echo "Error: no suitable compiler found for kernel build."
    return 1
  fi

  # Vérifier que NASM est disponible
  require_cmd "$NASM_BIN"

  # Define source files and object files
  KERNEL_ENTRY_ASM="$SRC_DIR/kernel/kernel_entry.asm"
  KERNEL_C="$SRC_DIR/kernel/kernel.c"
  MEMORY_C="$SRC_DIR/memory/memory.c"
  VGA_C="$SRC_DIR/drivers/vga.c"
  
  KERNEL_ENTRY_O="$OUT_DIR/kernel_entry.o"
  KERNEL_O="$OUT_DIR/kernel.o"
  MEMORY_O="$OUT_DIR/memory.o"
  VGA_O="$OUT_DIR/vga.o"
  
  KERNEL_BIN="$OUT_DIR/kernel.bin"
  LINKER_LD="$SRC_DIR/kernel/linker.ld"

  # Common compiler flags for 32-bit kernel
  COMMON_CFLAGS="$CFLAGS -ffreestanding -fno-pic -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs -Wall -Wextra -Werror -I$SRC_DIR/includes"

  mkdir -p "$OUT_DIR"

  # Assembler kernel_entry.asm
  if [[ -f "$KERNEL_ENTRY_ASM" ]]; then
    echo "Assembling kernel_entry.asm..."
    "$NASM_BIN" -f elf32 "$KERNEL_ENTRY_ASM" -o "$KERNEL_ENTRY_O"
    echo "Built: $KERNEL_ENTRY_O"
  else
    echo "Error: kernel_entry.asm not found at $KERNEL_ENTRY_ASM"
    return 1
  fi

  # Compile kernel.c
  if [[ -f "$KERNEL_C" ]]; then
    echo "Compiling kernel.c..."
    "$CC" $COMMON_CFLAGS -c "$KERNEL_C" -o "$KERNEL_O"
    echo "Built: $KERNEL_O"
  else
    echo "Error: kernel.c not found at $KERNEL_C"
    return 1
  fi

  # Compile memory.c
  if [[ -f "$MEMORY_C" ]]; then
    echo "Compiling memory.c..."
    "$CC" $COMMON_CFLAGS -c "$MEMORY_C" -o "$MEMORY_O"
    echo "Built: $MEMORY_O"
  else
    echo "Warning: memory.c not found, skipping..."
  fi

  # Compile vga.c if it exists
  if [[ -f "$VGA_C" ]]; then
    echo "Compiling vga.c..."
    "$CC" $COMMON_CFLAGS -c "$VGA_C" -o "$VGA_O"
    echo "Built: $VGA_O"
  else
    echo "Note: vga.c not found, skipping..."
  fi

  # Collect all object files (kernel_entry.o MUST be first)
  OBJECT_FILES="$KERNEL_ENTRY_O $KERNEL_O"
  [[ -f "$MEMORY_O" ]] && OBJECT_FILES="$OBJECT_FILES $MEMORY_O"
  [[ -f "$VGA_O" ]] && OBJECT_FILES="$OBJECT_FILES $VGA_O"

  # Link all object files to create kernel.bin
  if [[ -f "$LINKER_LD" ]]; then
    echo "Linking kernel with linker script..."
    "$LD" -m elf_i386 -T "$LINKER_LD" -o "$KERNEL_BIN" $OBJECT_FILES
    echo "Built kernel binary: $KERNEL_BIN"
  else
    echo "Warning: linker script not found at $LINKER_LD"
    echo "Creating kernel.bin without linker script..."
    
    # Create a temporary ELF file first, then convert to binary
    KERNEL_ELF="$OUT_DIR/kernel.elf"
    "$LD" -m elf_i386 -Ttext 0x1000 --oformat elf32-i386 -o "$KERNEL_ELF" $OBJECT_FILES
    "$OBJCOPY" -O binary "$KERNEL_ELF" "$KERNEL_BIN"
    rm -f "$KERNEL_ELF"
    echo "Built kernel binary (without linker script): $KERNEL_BIN"
  fi

  # Display kernel size
  if [[ -f "$KERNEL_BIN" ]]; then
    KERNEL_SIZE=$(stat -c%s "$KERNEL_BIN" 2>/dev/null || wc -c < "$KERNEL_BIN")
    echo "Kernel size: $KERNEL_SIZE bytes"
  fi
}

run_qemu() {
  require_cmd "$QEMU_BIN"
  BOOT_IMG="$OUT_DIR/boot.img"
  if [[ ! -f "$BOOT_IMG" ]]; then
    echo "Image not found: $BOOT_IMG. Building first..."
    build_bootloader
  fi
  # Ensure permissive permissions (helps with some host setups)
  chmod u+rw,go+r "$BOOT_IMG" 2>/dev/null || true
    echo "Starting QEMU with HollowOS..."
  "$QEMU_BIN" \
	-drive file="$BOOT_IMG",format=raw,if=floppy \
    -boot a \
    -m 32M \
    -serial mon:stdio \
    -no-shutdown \
    -no-reboot
  wait || {
    echo "Primary QEMU run failed; retrying with a temporary copy..." >&2
    TMP_IMG="$(mktemp -t hollowos.boot.XXXXXX.img)" || {
      echo "Failed to create temp image; aborting." >&2
      exit 1
    }
    cp "$BOOT_IMG" "$TMP_IMG"
    chmod u+rw,go+r "$TMP_IMG" 2>/dev/null || true
    "$QEMU_BIN" \
      -drive file="$TMP_IMG",format=raw,if=floppy \
      -boot a \
      -m 32M \
      -no-shutdown \
      -serial mon:stdio \
      -no-reboot &
    wait
    status=$?; rm -f "$TMP_IMG"; exit $status
  }
}

clean_build() {
  rm -rf "$OUT_DIR"
  echo "Cleaned: $OUT_DIR"
}

target="${1:-build}"
case "$target" in
  (build) build_kernel; build_bootloader ;;
  (run)   run_qemu ;;
  (clean) clean_build ;;
  (*)     usage; exit 1 ;;
esac