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

# Set up page tables for one-to-map linear to physical map for the
# first 64 MB of RAM.
# See [IA32-v3a] section 3.7.6 "Page-Directory and Page-Table Entries"
# for a description of the bits in %eax.

	movw $0x1000, %ax
	movw %ax, %es
	movl $0x7, %eax
	movl $0x4000, %ecx
	subl %edi, %edi
1:	movl %eax, %es:(%di)
	addw $4, %di
	addl $0x1000, %eax
	loop 1b

# Set page directory base register.

	movl $0xf000, %eax
	movl %eax, %cr3

#### Switch to protected mode.

# First, disable interrupts.  We won't set up the IDT until we get
# into C code, so any interrupt would blow us away.

	cli

# Protected mode requires a GDT, so point the GDTR to our GDT.
# We need a data32 prefix to ensure that all 32 bits of the GDT
# descriptor are loaded (default is to load only 24 bits).
# The CPU doesn't need an addr32 prefix but ELF doesn't do 16-bit
# relocations.

	data32 addr32 lgdt gdtdesc - LOADER_PHYS_BASE - LOADER_KERN_BASE

# Then we turn on the following bits in CR0:
#    PE (Protect Enable): this turns on protected mode.
#    PG (Paging): turns on paging.
#    WP (Write Protect): if unset, ring 0 code ignores
#       write-protect bits in page tables (!).
#    EM (Emulation): forces floating-point instructions to trap.
#       We don't support floating point.

	movl %cr0, %eax
	orl $CR0_PE | CR0_PG | CR0_WP | CR0_EM, %eax
	movl %eax, %cr0

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
