[BITS 16]
[ORG 0x7C00]

start:
  cli
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7C00        ; Stack pointer
  
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
  mov al, 10            ; Number of sectors to read (5KB kernel)
  mov ch, 0x00          ; Cylinder 0
  mov cl, 0x02          ; Sector 2 (kernel starts at sector 2)
  mov dh, 0x00          ; Head 0
  mov dl, 0x00          ; Drive 0 (floppy)
  mov bx, 0x1000        ; Load kernel at 0x1000
  mov es, ax            ; ES = 0x0000
  int 0x13              ; BIOS disk read
  jc disk_error         ; Jump if error
  
  jmp 0x0000:0x1000     ; Far jump to 32 bits kernel

disk_error:
  mov si, disk_msg
.disk_print:
  lodsb
  test al, al
  jz .hang
  mov ah, 0x0E
  mov bh, 0x00
  mov bl, 0x04          ; Red color
  int 0x10
  jmp .disk_print

.hang:
  hlt
  jmp .hang

msg db "HollowOS stage 1 OK, loading kernel...", 0x0D, 0x0A, 0
disk_msg db "Disk read error!", 0x0D, 0x0A, 0

times 510-($-$$) db 0
dw 0xAA55
