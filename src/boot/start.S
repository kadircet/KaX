#include "boot/boot.h"

	.section .start

	.code32

.globl start
start:
1:	mov $SEL_KDSEG, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	mov %ax, %ss
	addl $LOADER_PHYS_BASE, %esp
	movl $0, %ebp			# Null-terminate main()'s backtrace

#### Call main().

	jmp main

# main() shouldn't ever return.  If it does, spin.

1:	jmp 1b

