#include "boot/boot.h"

	.code16
	xor	%ax, %ax
	mov %ax, %ds
	mov %ax, %ss
	mov %ax, %es
	mov $0xf000, %esp
	
	call puts
	.string "Loading KaX\r\n"
	
	mov $(LOADER_KERN_BASE/0x10), %ax
	mov %ax, %es
	xor %bx, %bx
	call load_setup
	
	call puts
	.string "            [Loaded]\r\n"
	
	mov %es:0x18, %dx
	mov %dx, addr
	movw $(LOADER_KERN_BASE/0x10), addr+2
	ljmp *addr
	
load_setup:
	pusha
	
	call puts
	.string "."
	
	mov $0x0220, %ax	# AH->sr	AL->nrSec
	mov $0x0002, %cx	# CH->cyl	CL->sec
	mov $0x00, %dh		# DH->head	DL->drive
	int $0x13
	or	%ah, %ah
	jz popa_ret
	call puts
	.string "FUCK THAT SHIT"
hlt:jmp hlt
	
puts:
	xchg %si, %ss:(%esp)
	push %ax
next_char:
	mov %cs:(%si), %al
	inc %si
	test %al, %al
	jz 1f
	call putc
	jmp next_char
1:	pop %ax
	xchg %si, %ss:(%esp)
	ret
	
putc:
	pusha
	sub %bh, %bh
	mov $0x0e, %ah
	int $0x10
	
popa_ret:
	popa
	ret				# Error code still in CF

addr:
	.word 0x0000
	.word 0x0000
	
	.org LOADER_SIG - LOADER_BASE
	.word 0xaa55
