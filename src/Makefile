CC = gcc -m32
LD = ld -melf_i386
OBJCOPY = objcopy

SRCDIR = .
DEFINES =
WARNINGS = -Wall -W -Wstrict-prototypes -Wmissing-prototypes -Wsystem-headers
CFLAGS = -msoft-float -O -fno-stack-protector -fno-builtin
CPPFLAGS = -nostdinc -I$(SRCDIR) -I$(SRCDIR)/lib -I$(SRCDIR)/include
ASFLAGS = -Wa,--gstabs
LDFLAGS =
DEPS = -MMD -MF $(@:.o=.d)
KERNEL_SUBDIRS = boot init

all: loader.bin kernel.bin
	cat loader.bin kernel.bin > KaX.img
	#make clean
	
run: all
	bochs -f KaX.bochs

#bootloader.
boot_SRC = boot/setup.S		# Setup code.
boot_SRC+= boot/setup_c.c	# Misc
boot_SRC+= boot/start.S		# Startup code.

#init
init_SRC = init/init.c			# Main

SOURCES = $(foreach dir,$(KERNEL_SUBDIRS),$($(dir)_SRC))
OBJECTS = $(patsubst %.c,%.o,$(patsubst %.S,%.o,$(SOURCES)))
DEPENDS = $(patsubst %.o,%.d,$(OBJECTS))

kernel.lds.s: CPPFLAGS += -P
kernel.lds.s: kernel.lds.S

kernel.o: kernel.lds.s $(OBJECTS)
	$(LD) -T $< -o $@ $(OBJECTS)

kernel.bin: kernel.o
	$(OBJCOPY) -R .note -R .comment -S $< $@

boot/boot.o: boot/boot.S
	$(CC) -c $< -o $@ $(ASFLAGS) $(CPPFLAGS) $(DEFINES)

loader.bin: boot/boot.o
	$(LD) -N -e 0 -Ttext 0x7c00 --oformat binary -o $@ $<

%.o: %.c
	$(CC) -c $< -o $@ $(CFLAGS) $(CPPFLAGS) $(WARNINGS) $(DEFINES) $(DEPS)

%.o: %.S
	$(CC) -c $< -o $@ $(ASFLAGS) $(CPPFLAGS) $(DEFINES) $(DEPS)
	
clean:
	rm -f $(OBJECTS) $(DEPENDS) 
	rm -f boot/boot.o kernel.lds.s threads/loader.d
	rm -f kernel.o kernel.lds.s
	rm -f kernel.bin loader.bin
	#rm -f KaX.img
	
-include $(DEPENDS)
