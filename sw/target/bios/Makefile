ZAS?=sjasmplus.exe

BIOS_SRCS=bios.asm

.PHONY: all clean bios

all: bios.rom
clean:
	rm -f bios.rom

bios: bios.rom

bios.rom: $(BIOS_SRCS)
	$(ZAS) bios.asm