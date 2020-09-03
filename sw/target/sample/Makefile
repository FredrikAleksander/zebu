ZCC?=zcc.exe

SAMPLE_SRCS=sample.c

.PHONY: all clean sample

all: sample.rom
clean:
	rm -f sample.rom
	rm -f sample_BSS.bin
	rm -f sample_CODE.bin
	rm -f sample_DATA.bin
	rm -f sample_UNASSIGNED.bin

sample: sample.rom
sample.rom: $(SAMPLE_SRCS)
	$(ZCC) +z80 -vn -SO3 -clib=sdcc_iy --max-allocs-per-node200000 $(SAMPLE_SRCS) -o sample.bin -lm -create-app -pragma-include:pragma.inc