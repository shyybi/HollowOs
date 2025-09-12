ENTRY(_start)
SECTIONS
{
    . = 0x8000;
    .text : ALIGN(4096)
    {
        *(.text)
    }

    .rodata : ALIGN(4096)
    {
        *(.rodata)
    }

    .data : ALIGN(4096)
    {
        *(.data)
    }

    .bss : ALIGN(4096)
    {
        *(.bss)
    }
        
    .asm : ALIGN(4096)
    {
        *(.asm)
    }
}