#ifndef STAGE1_LOADER_H
#define STAGE1_LOADER_H

#define LOADER_BASE 0x7c00
#define LOADER_END  0x7e00

#define LOADER_KERN_BASE 0x90000

/* Kernel virtual address at which all physical memory is mapped.
   Must be aligned on a 4 MB boundary. */
#define LOADER_PHYS_BASE 0xc0000000     /* 3 GB. */

#define LOADER_SIG (LOADER_END - LOADER_SIG_LEN)
#define LOADER_PARTS (LOADER_SIG - LOADER_PARTS_LEN)

#define LOADER_SIG_LEN 2
#define LOADER_PARTS_LEN 64

#define SEL_NULL        0x00
#define SEL_KCSEG       0x08
#define SEL_KDSEG       0x10

#endif
