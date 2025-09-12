[BITS 32]

global _start
extern kernel_main

_start:
    ; We're already in protected mode, segments already set up
    call kernel_main

hang:
    jmp hang