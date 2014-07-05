void cls(void);
void puts(char*);
int main(void);

unsigned short *vidmem = (unsigned short *)0XB8000;

void cls()
{
	int r,c;
	for(r=0;r<25;r++)
		for(c=0;c<80;c++)
			*(vidmem+r*80+c) = (0x07<<8) | ' ';
}

void puts(char *str)
{
	int r=0,c=0;
	while(*str)
	{
		*(vidmem+r*80+c) = (0x07<<8) | *str;
		str++;
		c++;
		r+=c/80;
		c%=80;
	}
}

int main()
{
	cls();
	puts("Hello from KaX!!");	
	for(;;);
}
