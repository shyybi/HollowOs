ENTRY(start)
OUTPUT_FORMAT(binary)

SECTIONS
{
    . = 0x1000;
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