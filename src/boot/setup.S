#include <boot/boot.h>
.code16
.section .setup

#define CR0_PE 0x00000001      /* Protection Enable. */
#define CR0_EM 0x00000004      /* (Floating-point) Emulation. */
#define CR0_PG 0x80000000      /* Paging. */
#define CR0_WP 0x00010000      /* Write-Protect enable in kernel mode. */

.globl setup
setup:
	#GetMemSize (MAX 64MB)
	mov $(LOADER_KERN_BASE/0x10), %ax
	mov %ax, %ds

	movb $0x88, %ah
	int $0x15
	addl $1024, %eax	# Total kB memory
	shrl $2, %eax		# Total 4 kB pages
	addr32 movl %eax, ram_size - LOADER_PHYS_BASE - KERNEL_BASE

	cli
	cld
	mov $(LOADER_KERN_BASE/0x10), %ax
	mov %ax, %ds
	mov $(KERNEL_BASE/0x10), %ax
	mov %ax, %es
copy:
	subl %edi, %edi
	subl %esi, %esi
	movl $0x8000, %ecx	#32kB at a time
	rep
	movsw
	
	mov %ds, %ax
	add $0x1000, %ax
	mov %ax, %ds
	mov %es, %ax
	add $0x1000, %ax
	mov %ax, %es
	cmp $(LOADER_KERN_BASE/0x10), %ax
	jnz copy

	mov $(LOADER_KERN_BASE/0x10), %ax
	mov %ax, %ds

	#Enable A20
1:	inb $0x64, %al
	testb $0x2, %al
	jnz 1b
	
	movb $0xd1, %al
	outb %al, $0x64
	
1:	inb $0x64, %al
	testb $0x2, %al
	jnz 1b
	
	movb $0xdf, %al
	outb %al, $0x60
	
1:	inb $0x64, %al
	testb $0x2, %al
	jnz 1b

#### Switch to protected mode.
	cli
	data32 addr32 lgdt gdtdesc - LOADER_PHYS_BASE - KERNEL_BASE

	movl %cr0, %eax
	orl $CR0_PE | CR0_WP | CR0_EM, %eax
	movl %eax, %cr0

# Jump to our startup code :)
	data32 ljmp $SEL_KCSEG, $start

	.align 8
gdt:
	.quad 0x0000000000000000	# Null segment.  Not used by CPU.
	.quad 0x00cf9a000000ffff	# System code, base 0, limit 4 GB.
	.quad 0x00cf92000000ffff        # System data, base 0, limit 4 GB.

gdtdesc:
	.word	gdtdesc - gdt - 1	# Size of the GDT, minus 1 byte.
	.long	gdt			# Address of the GDT.

.globl .ram_size
ram_size:
	.long 0x00
