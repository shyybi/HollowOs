#include "../includes/kernel.h"

void kernel_main(void) {
	const char *str = "HollowOs Kernel Loaded!";
	char *vidptr = (char*)0xb8000; /* video mem */
	unsigned int i = 0;
	unsigned int j = 0;

	/* clearing screen */
	while(j < 80 * 25 * 2) {
        vidptr[j] = ' '; 				/*Blank chara ' ' */
        vidptr[j+1] = 0x07; 		/* Light grey */
        j = j + 2;
    }
    
  j = 0;
  while(str[j] != '\0') {
    vidptr[i] = str[j];
    vidptr[i+1] = 0x07;
    ++j;
    i = i + 2;
  }
  
  // loop 
  for(;;) {
   for(volatile int k = 0; k < 1000000; k++) {
           __asm__ volatile ("nop");
    }
  }
}