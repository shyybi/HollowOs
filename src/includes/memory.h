#ifndef MEMORY_H
#define MEMORY_H

// Define size_t for kernel environment (no stddef.h available)
typedef unsigned int size_t;

void *memset(void *ptr, int c, size_t size);
int memcmp(void *s1, void *s2, int count);
void *memcpy(void *dest, void *src, int len);

#endif