.PHONY: all clean z80_mmu_tb z80_spimaster_tb z80_waitstate_generator_tb simulator bios

GTKWAVE?=gtkwave
IVERILOG?=iverilog
VVP?=vvp
VFLAGS?=--trace
VERILATOR_INCLUDE_DIR?=/usr/share/verilator/include
ROMFILE?=bios/rom.bin
SJASMPLUS?=sjasmplus.exe

SOURCES=config_register.v serclk_generator.v shiftreg_in.v shiftreg_out.v z80_bus_controller.v z80_mmu.v z80_spimaster.v z80_waitstate_generator.v simulator.v
SIM_LIB=obj_dir/Vsimulator__ALL.a
SIM_BIN=zebusim.exe

TESTS=z80_mmu_tb.vvp z80_waitstate_generator_tb.vvp z80_spimaster_tb.vvp
RESULTS=z80_mmu_tb.vcd z80_waitstate_generator_tb.vcd z80_spimaster_tb.vcd simulator.vcd

all: $(RESULTS)
clean:
	rm -f bios/rom.bin
	rm -rf obj_dir
	rm -f $(TESTS)
	rm -f $(RESULTS)

%.vvp: %.v
	$(IVERILOG) -g2012 -o $@ $<
%.vcd: %.vvp
	$(VVP) $<

bios/rom.bin: bios/bios.asm
	$(SJASMPLUS) $<

bios: bios/rom.bin

z80_mmu_tb: z80_mmu_tb.vcd z80_mmu_tb.gtkw
	$(GTKWAVE) z80_mmu_tb.gtkw

z80_spimaster_tb: z80_spimaster_tb.vcd z80_spimaster_tb.gtkw
	$(GTKWAVE) z80_spimaster_tb.gtkw

z80_waitstate_generator_tb: z80_waitstate_generator_tb.vcd z80_waitstate_generator_tb.gtkw
	$(GTKWAVE) z80_waitstate_generator_tb.gtkw

obj_dir/Vsimulator.cpp: $(SOURCES)
	verilator $(VFLAGS) --top-module simulator -Itv80/rtl/core -Iuart -Wno-fatal -cc simulator.v

obj_dir/Vsimulator__ALL.a: obj_dir/Vsimulator.cpp obj_dir/Vsimulator.h
	cd obj_dir/ && $(MAKE) -f Vsimulator.mk
	$(MAKE -C obj_dir/ -f Vsimulator.mk)

$(SIM_BIN): simulator.cpp uart/uart_simulator.hpp uart/uart_simulator.cpp uart/uart_driver.hpp uart/uart_driver_stdio.hpp uart/uart_driver_stdio.cpp testbench.hpp tb_clock.hpp $(SIM_LIB)
	$(CXX) simulator.cpp uart/uart_simulator.cpp uart/uart_driver_stdio.cpp $(VERILATOR_INCLUDE_DIR)/verilated_vcd_c.cpp  $(VERILATOR_INCLUDE_DIR)/verilated.cpp obj_dir/Vsimulator__ALL.a -o $(SIM_BIN) -I. -Iobj_dir/ -I$(VERILATOR_INCLUDE_DIR)

simulator: $(SIM_BIN) bios/rom.bin bios/bios.asm
	./$(SIM_BIN) --rom $(ROMFILE) --trace simulator.vcd