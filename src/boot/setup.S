#include <boot/boot.h>
.code16
.section .setup

#define CR0_PE 0x00000001      /* Protection Enable. */
#define CR0_EM 0x00000004      /* (Floating-point) Emulation. */
#define CR0_PG 0x80000000      /* Paging. */
#define CR0_WP 0x00010000      /* Write-Protect enable in kernel mode. */

.globl setup
setup:
	mov $(LOADER_KERN_BASE/0x10), %ax
	mov %ax, %ds
	mov %ax, %es
	cld
	
	#GetMemSize (MAX 64MB)
	movb $0x88, %ah
	int $0x15
	addl $1024, %eax	# Total kB memory
	cmp $0x10000, %eax	# Cap at 64 MB	
	jbe 1f
	mov $0x10000, %eax
1:	shrl $2, %eax		# Total 4 kB pages
	addr32 movl %eax, ram_size - LOADER_PHYS_BASE - LOADER_KERN_BASE
	
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

# Create page directory at 0xf000 (60 kB) and fill with zeroes.
	mov $0xf00, %ax
	mov %ax, %es
	subl %eax, %eax
	subl %edi, %edi
	movl $0x400, %ecx
	rep stosl

# Add page-directory entries and 
# create identical PDE starting at LOADER_PHYS_BASE
# only for fist 64MB (for now)
	movl $0x10007, %eax
	movl $0x11, %ecx
	subl %edi, %edi
1:	movl %eax, %es:(%di)
	movl %eax, %es:LOADER_PHYS_BASE >> 20(%di)
	addw $4, %di
	addl $0x1000, %eax
	loop 1b

# Set up page directories to 1-1 map with first 64MB of memory
	movw $0x1000, %ax
	movw %ax, %es
	movl $0x7, %eax
	movl $0x4000, %ecx
	subl %edi, %edi
1:	movl %eax, %es:(%di)
	addw $4, %di
	addl $0x1000, %eax
	loop 1b

# Tell cpu where the page directory is
	movl $0xf000, %eax
	movl %eax, %cr3

#### Switch to protected mode.
	cli

	data32 addr32 lgdt gdtdesc - LOADER_PHYS_BASE - LOADER_KERN_BASE

	movl %cr0, %eax
	orl $CR0_PE | CR0_PG | CR0_WP, %eax
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
