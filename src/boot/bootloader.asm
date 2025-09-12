[BITS 16]
[ORG 0x7C00]

_start:
    ; Setup segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Print bootloader OK
    mov si, boot_msg
    call print_string

    ; Load kernel from disk
    mov ah, 0x02        ; Read sectors
    mov al, 10          ; Number of sectors to read
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2 (after bootloader)
    mov dh, 0           ; Head 0
    mov dl, 0           ; Drive 0 (floppy A)
    mov bx, 0x8000      ; Load kernel at 0x8000
    int 0x13            ; BIOS disk interrupt

    jc disk_error       ; Jump if carry flag set (error)

    ; Print kernel loaded
    mov si, kernel_msg
    call print_string

    ; Enter protected mode
    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:protected_mode

[BITS 32]
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Print entering kernel
    mov si, enter_kernel_msg
    call print_string

    ; Jump to kernel entry point
    jmp 0x8000

disk_error:
    mov si, error_msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

boot_msg db 'Bootloader OK', 13, 10, 0
kernel_msg db 'Kernel loaded', 13, 10, 0
enter_kernel_msg db 'Jumping to kernel', 13, 10, 0

error_msg db 'Disk read error!', 0

align 8
gdt_start:
    ; Null descriptor
    dw 0x0000, 0x0000
    db 0x00, 0x00, 0x00, 0x00

    ; Code segment: base=0, limit=0xFFFFF, type=0x9A, gran=0xCF
    dw 0xFFFF, 0x0000
    db 0x00, 0x9A, 0xCF, 0x00

    ; Data segment: base=0, limit=0xFFFFF, type=0x92, gran=0xCF
    dw 0xFFFF, 0x0000
    db 0x00, 0x92, 0xCF, 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; Boot signature
times 510-($-$$) db 0
dw 0xAA55