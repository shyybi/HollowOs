#include "../includes/kernel.h"


void kernel_main(void) {
    // Write directly to VGA memory to test
    char *video = (char*)0xB8000;
    video[0] = 'K';
    video[1] = 0x07; // White on black
    video[2] = 'E';
    video[3] = 0x07;
    video[4] = 'R';
    video[5] = 0x07;
    video[6] = 'N';
    video[7] = 0x07;
    
    while(1) {} // Infinite loop
}
/*
void kernel_main(void) {
	const char *str = "HollowOs Kernel Loaded!";
	char *vidptr = (char*)0xb8000; //video mem 
	unsigned int i = 0;
	unsigned int j = 0;

	// clearing screen 
	while(j < 80 * 25 * 2) {
        vidptr[j] = ' '; 				//Blank chara ' ' 
        vidptr[j+1] = 0x07; 		//Light grey
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
*/