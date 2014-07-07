void cls(void);
void puts(char*);
int main(void);
#include <stdint.h>

typedef struct SMAP_entry
{
	uint64_t Base; // base address QWORD
	uint64_t Length; // length QWORD
	uint32_t Type; // entry Ttpe
	uint32_t ACPI; // exteded
}__attribute__((packed)) SMAP_entry_t;


unsigned short *vidmem = (unsigned short *)0xB8000;
int r,c;

void cls()
{
	for(r=0;r<25;r++)
		for(c=0;c<80;c++)
			*(vidmem+r*80+c) = (0x07<<8) | ' ';
			
	r=0;
	c=0;
}

void putch(char ch)
{
	*(vidmem+r*80+c) = (0x07<<8) | ch;
	c++;
	r+=c/80;
	c%=80;
}

void put(char *str)
{
	while(*str)
	{
		putch(*str++);
	}
}

void puts(char *str)
{
	put(str);
	r++;
	c=0;
}

void putint(unsigned long x, int base)
{
	char *map = "0123456789ABCDEF";
	char *a = "        ";
	char *b=a;
	while(b-a<8)
		*b++ = '0';
	b--;
	while(x)
	{
		*b-- = map[x%base];
		x/=base;
	}
	b++;
	if(base==10)
		a=b;
	put(a);
}

void putmap(struct SMAP_entry map)
{
	put("0x");
	putint(map.Base>>32, 0x10);
	putint(map.Base&0xFFFFFFFF, 0x10);
	putch('|');
	put("0x");
	putint(map.Length>>32, 0x10);
	putint(map.Length&0xFFFFFFFF, 0x10);
	putch('|');
	put("0x");
	putint(map.Type, 0x10);
	putch('|');
	put("0x");
	putint(map.ACPI, 0x10);
	puts("");
}

extern int _end, _start;
extern int ram_size;
extern struct SMAP_entry ram_map;
int main()
{
	long long mem_size=0;
	int i;
	cls();
	puts("Hello from KaX!!");
	struct SMAP_entry* memory = &ram_map;
	for(i=0;i<ram_size;i++)
	{
		mem_size += memory[i].Length;
		putmap(memory[i]);
	}
	put("Memory size: ");
	putint(mem_size/0x100000, 10);
	puts("MB");
	
	put("Kernel size: ");
	putint((int)(&_end - &_start)/1024, 10);
	puts("KB");
	for(;;);
}
