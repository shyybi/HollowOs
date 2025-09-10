[BITS 32]

global _start
global kernel_reg
extern kernel_main

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
        mov ax, DATA_SEG
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        mov ebp, 0x00200000
        mov esp, ebp

        ; enable a20
        in al, 0x92
        or al, 2
        out 0x92, al

        ; Remap master PIC
        mov al, 00010001b ; PIC init mode
        out 0x20, al

        mov al, 0x21; Interrupt 0x20 (master isr start)
        out 0x21, al
        
        mov al, 000000001b
        out 0x21, al
        ; end Remap

        call kernel_main

        jmp $

kernel_reg:
        mov ax, 0x10
        mov ds, ax
        mov es, ax
        mov gs, ax
        mov fs, ax
        ret

times 510-($-$$) db 0