[BITS 16]
[ORG 0x7C00]

start:
  cli
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7C00
  sti

  mov si, msg
.print:
  lodsb
  test al, al
  jz .hang
  mov ah, 0x0E         ; BIOS teletype
  mov bh, 0x00
  mov bl, 0x07         ; light gray
  int 0x10
  jmp .print

.hang:
  cli
  hlt
  jmp .hang

msg db "HollowOS stage 1 OK, hi from Shyybi", 0

times 510-($-$$) db 0
dw 0xAA55