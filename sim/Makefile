.PHONY: all clean simulator

VFLAGS?=--trace
VERILATOR_INCLUDE_DIR?=/usr/share/verilator/include
SOURCES=../config_register.v ../serclk_generator.v ../shiftreg_in.v ../shiftreg_out.v ../z80_bus_controller.v ../z80_mmu.v ../z80_spimaster.v ../z80_waitstate_generator.v simulator.v
SIM_LIB=obj_dir/Vsimulator__ALL.a
SIM_BIN=zebusim.exe

all: simulator
clean:
	rm -rf obj_dir

obj_dir/Vsimulator.cpp: $(SOURCES)
	verilator $(VFLAGS) --top-module simulator -I../tv80/rtl/core -Iuart -I.. -Wno-fatal -cc simulator.v

obj_dir/Vsimulator__ALL.a: obj_dir/Vsimulator.cpp obj_dir/Vsimulator.h
	cd obj_dir/ && $(MAKE) -f Vsimulator.mk
	$(MAKE -C obj_dir/ -f Vsimulator.mk)

$(SIM_BIN): simulator.cpp uart/uart_simulator.hpp uart/uart_simulator.cpp uart/uart_driver.hpp uart/uart_driver_stdio.hpp uart/uart_driver_stdio.cpp testbench.hpp tb_clock.hpp $(SIM_LIB)
	$(CXX) simulator.cpp uart/uart_simulator.cpp uart/uart_driver_stdio.cpp $(VERILATOR_INCLUDE_DIR)/verilated_vcd_c.cpp  $(VERILATOR_INCLUDE_DIR)/verilated.cpp obj_dir/Vsimulator__ALL.a -o $(SIM_BIN) -I. -Iobj_dir/ -I$(VERILATOR_INCLUDE_DIR)

simulator: $(SIM_BIN)