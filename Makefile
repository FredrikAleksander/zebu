.PHONY: all test clean z80_mmu_tb z80_spimaster_tb z80_waitstate_generator_tb simulator bios sample

GTKWAVE?=gtkwave
IVERILOG?=iverilog
VVP?=vvp

TESTS=z80_mmu_tb.vvp z80_waitstate_generator_tb.vvp z80_spimaster_tb.vvp
RESULTS=z80_mmu_tb.vcd z80_waitstate_generator_tb.vcd z80_spimaster_tb.vcd


all: test simulator bios sample
test: $(RESULTS)
clean:
	rm -f $(TESTS)
	rm -f $(RESULTS)
	make -C sw/target/bios clean
	make -C sw/target/sample clean
	make -C sim clean

%.vvp: tests/%.v
	$(IVERILOG) -I. -g2012 -o $@ $<
%.vcd: %.vvp
	$(VVP) $<

z80_mmu_tb: z80_mmu_tb.vcd z80_mmu_tb.gtkw
	$(GTKWAVE) z80_mmu_tb.gtkw

z80_spimaster_tb: z80_spimaster_tb.vcd z80_spimaster_tb.gtkw
	$(GTKWAVE) z80_spimaster_tb.gtkw

z80_waitstate_generator_tb: z80_waitstate_generator_tb.vcd z80_waitstate_generator_tb.gtkw
	$(GTKWAVE) z80_waitstate_generator_tb.gtkw

simulator:
	make -C sim simulator

bios:
	make -C sw/target/bios bios.rom

sample:
	make -C sw/target/sample sample.rom