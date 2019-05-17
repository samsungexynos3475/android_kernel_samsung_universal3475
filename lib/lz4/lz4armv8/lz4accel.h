#ifndef _LZ4_ACCEL_H
#define _LZ4_ACCEL_H

static inline int lz4_decompress_accel_enable(void) { return 0; }
static inline int lz4_decompress_asm(void **dstPtr, void *dest, void *destEnd, void **srcPtr, void *srcEnd, void *dip) { return -1; }

#endif
