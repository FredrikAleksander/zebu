ZCC?=zcc.exe

HEADERS=kprint.h kprintf.h
SRCS=sample.c kprint.c kprintf.c

.PHONY: all clean sample

all: sample.rom
clean:
	rm -f sample.rom
	rm -f sample_BSS.bin
	rm -f sample_CODE.bin
	rm -f sample_DATA.bin
	rm -f sample_UNASSIGNED.bin

sample: sample.rom
sample.rom: $(SRCS) $(HEADERS)
	$(ZCC) +z80 -vn -SO3 -clib=sdcc_iy --max-allocs-per-node200000 $(SRCS) -o sample.bin -lm -create-app -pragma-include:pragma.inc