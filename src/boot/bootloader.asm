[BITS 16]
[ORG 0x7C00]

start:
  cli
  xor ax, ax
  mov si, msg
.print:
  lodsb
  test al, al
  jz .load_kernel
  mov ah, 0x0E         ; BIOS teletype
  mov bh, 0x00
  mov bl, 0x07         ; light gray
  int 0x10
  jmp .print

.load_kernel:
  mov ah, 0x02          ; BIOS: Read Sectors
  mov al, 10            ; Number of sectors to read (adjust according to kernel size)
  mov ch, 0x00          ; Cylinder 0
  mov cl, 0x02          ; Sector 2 (bootloader = sector 1)
  mov dh, 0x00          ; Head 0
  mov dl, 0x00          ; Disk 0 (floppy)
  mov bx, 0x1000        ; Destination address (offset)
  mov es, ax            ; ES = 0x0000 (segment)
  int 0x13              ; BIOS call
  jc disk_error         ; If error, jump to disk_error
  jmp 0x1000            ; Jump to kernel

disk_error:
  mov si, disk_msg
.disk_print:
  lodsb
  test al, al
  jz .hang
  mov ah, 0x0E
  mov bh, 0x00
  mov bl, 0x04        ; rouge
  int 0x10
  jmp .disk_print

.hang:
  jmp .hang

msg db "HollowOS stage 1 OK, hi from Shyybi", 0
disk_msg db "Disk read error!", 0

times 510-($-$$) db 0
dw 0xAA55
