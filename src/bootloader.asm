[BITS 32]

load32:
  mov ax, DATA_SEG
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  mov ebp, 0x00200000
	mov esp, ebp
  
	; fast enable a20
  in al, 0x92
  or al, 2
  out 0x92, al
  
	jmp $

	times 512-($- $$) db 0 ;