[BITS 16]

global _start
extern kernel_main

_start:
    cli

    lgdt [gdt_descriptor] ; Load GDT
    
    mov eax, cr0 ; Enable protected mode
    or eax, 1
    mov cr0, eax
    
    jmp 0x08:protected_mode  ; Far jump to 32-bit

[BITS 32]
protected_mode:
    ; segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    
    ; Call kernel main
    call kernel_main
    
hang:
    jmp hang

align 4 ; GDT aligned properly

gdt_start:
    ; Null descriptor
    dd 0x00000000
    dd 0x00000000

    ; Code segment
    dd 0x0000FFFF          ; Limit and base (low)
    dd 0x00CF9A00          ; Base (high) and flags

    ; Data segment
    dd 0x0000FFFF          ; Limit and base (low)  
    dd 0x00CF9200          ; Base (high) and flags

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start
