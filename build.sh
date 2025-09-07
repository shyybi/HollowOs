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

  echo "Built boot sector: $BOOT_BIN"
  echo "Bootable image:    $BOOT_IMG"
}

build_kernel_optional() {
	# Detect compiler
	if command -v i386-elf-gcc >/dev/null 2>&1; then
		CC=i386-elf-gcc
		LD=i386-elf-ld
		CFLAGS=""
	elif command -v x86_64-elf-gcc >/dev/null 2>&1; then
		CC=x86_64-elf-gcc
		LD=x86_64-elf-ld
		CFLAGS="-m32"
	else
		echo "Note: no cross-compiler found; skipping kernel build."
		return 0
	fi

	KERNEL_C="$SRC_DIR/kernel/kernel.c"
	KERNEL_O="$OUT_DIR/kernel.o"
	KERNEL_BIN="$OUT_DIR/kernel.bin"
	LINKER_LD="$SRC_DIR/linker.ld"

	if [[ -f "$KERNEL_C" && -f "$LINKER_LD" ]]; then
		"$CC" $CFLAGS -ffreestanding -I "$SRC_DIR/includes" -c "$KERNEL_C" -o "$KERNEL_O"
		"$LD" -m elf_i386 -T "$LINKER_LD" -o "$KERNEL_BIN" "$KERNEL_O"
		echo "Built kernel binary: $KERNEL_BIN"
	elif [[ -f "$KERNEL_C" ]]; then
		"$CC" $CFLAGS -ffreestanding -I "$SRC_DIR/includes" -c "$KERNEL_C" -o "$KERNEL_O"
		echo "Built kernel object (not linked): $KERNEL_O"
	else
		echo "Note: kernel.c not found; skipping kernel build."
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
  "$QEMU_BIN" \
	-drive file="$BOOT_IMG",format=raw,if=floppy,readonly=on \
    -boot a \
    -monitor stdio \
    -no-reboot -no-shutdown || {
    echo "Primary QEMU run failed; retrying with a temporary copy (read-only)..." >&2
    TMP_IMG="$(mktemp -t hollowos.boot.XXXXXX.img)" || {
      echo "Failed to create temp image; aborting." >&2
      exit 1
    }
    cp "$BOOT_IMG" "$TMP_IMG"
    chmod u+rw,go+r "$TMP_IMG" 2>/dev/null || true
    "$QEMU_BIN" \
      -drive file="$TMP_IMG",format=raw,if=floppy,readonly=on,snapshot=on \
      -boot a \
      -monitor stdio \
      -no-reboot -no-shutdown; \
    status=$?; rm -f "$TMP_IMG"; exit $status
  }
}

clean_build() {
  rm -rf "$OUT_DIR"
  echo "Cleaned: $OUT_DIR"
}

target="${1:-build}"
case "$target" in
  (build) build_bootloader; build_kernel_optional ;;
  (run)   run_qemu ;;
  (clean) clean_build ;;
  (*)     usage; exit 1 ;;
esac