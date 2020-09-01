.PHONY: all clean z80_mmu_tb

GTKWAVE?=gtkwave
IVERILOG?=iverilog
VVP?=vvp

VERILATOR_INCLUDE_DIR?=/mingw64/share/verilator/include

SOURCES=config_register.v serclk_generator.v shiftreg_in.v shiftreg_out.v z80_bus_controller.v z80_mmu.v z80_spimaster.v z80_waitstate_generator.v simulator.v
SIM_LIB=obj_dir/Vsimulator__ALL.a
SIM_BIN=zebusim.exe

TESTS=z80_mmu_tb.vvp z80_waitstate_generator_tb.vvp z80_spimaster_tb.vvp
RESULTS=z80_mmu_tb.vcd z80_waitstate_generator_tb.vcd z80_spimaster_tb.vcd

all: $(RESULTS)
clean:
	rm -f $(TESTS)
	rm -f $(RESULTS)

%.vvp: %.v
	$(IVERILOG) -g2012 -o $@ $<
%.vcd: %.vvp
	$(VVP) $<

z80_mmu_tb: z80_mmu_tb.vcd z80_mmu_tb.gtkw
	$(GTKWAVE) z80_mmu_tb.gtkw

z80_spimaster_tb: z80_spimaster_tb.vcd z80_spimaster_tb.gtkw
	$(GTKWAVE) z80_spimaster_tb.gtkw

z80_waitstate_generator_tb: z80_waitstate_generator_tb.vcd z80_waitstate_generator_tb.gtkw
	$(GTKWAVE) z80_waitstate_generator_tb.gtkw

obj_dir/Vsimulator.cpp: $(SOURCES)
	verilator -Icpu/cpu/alu -Icpu/cpu/bus -Icpu/cpu/control -Icpu/cpu/registers -Icpu/cpu/toplevel -Wno-fatal -cc simulator.v

obj_dir/Vsimulator__ALL.a: obj_dir/Vsimulator.cpp obj_dir/Vsimulator.h
	cd obj_dir/ && $(MAKE) -f Vsimulator.mk
	$(MAKE -C obj_dir/ -f Vsimulator.mk)

$(SIM_BIN): simulator.cpp $(SIM_LIB)
	$(CXX) simulator.cpp $(VERILATOR_INCLUDE_DIR)/verilated.cpp obj_dir/Vsimulator__ALL.a -o $(SIM_BIN) -Iobj_dir/ -I$(VERILATOR_INCLUDE_DIR)