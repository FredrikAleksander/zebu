project(simulator)
cmake_minimum_required(VERSION 3.15)

set(VFLAGS --trace)

if(DEFINED $ENV{VERILATOR_ROOT})
    set(VERILATOR_INCLUDE_DIR "$ENV{VERILATOR_ROOT}")
else()
    set(VERILATOR_INCLUDE_DIR /usr/share/verilator/include)
endif()

set(SIMLIB_HEADERS ${SIMLIB_HEADERS}
    simulator.hpp
    simulator_base.hpp
    simulator_driver.hpp
    simulator_message.hpp
    simulator_properties.hpp
    simulator_system.hpp
    systems/uart/uart_system.hpp
    systems/video/video_system.hpp
)
set(SIMLIB_SOURCES ${SIMLIB_SOURCES}
    simulator_driver.cpp
    systems/uart/uart_system.cpp
    systems/video/video_system.cpp
)

# add_library(simlib OBJECT ${SIMLIB_HEADERS} ${SIMLIB_SOURCES})
# set_property(TARGET simlib PROPERTY POSITION_INDEPENDENT_CODE ON)
# target_include_directories(simlib PUBLIC .)
# target_include_directories(simlib PUBLIC ${VERILATOR_INCLUDE_DIR})

set(ZEBUSIM_HEADERS ${ZEBUSIM_HEADERS} ${SIMLIB_HEADERS}
)

set(ZEBUSIM_SOURCES ${ZEBUSIM_SOURCES} ${SIMLIB_SOURCES}
    targets/zebusim/zebusim.cpp
)

set(VERILOG_SOURCES ${VERILOG_SOURCES} 
    ../config_register.v 
    ../serclk_generator.v
    ../shiftreg_in.v
    ../shiftreg_out.v
    ../z80_bus_controller.v
    ../z80_mmu.v
    ../z80_spimaster.v
    ../z80_waitstate_generator.v
    rom.v
    sram.v
    simulator.v
)

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/obj_dir/Vsimulator.h ${CMAKE_CURRENT_BINARY_DIR}/obj_dir/Vsimulator.cpp
                   DEPENDS ${VERILOG_SOURCES}
                   COMMAND verilator -CFLAGS "-fPIC" ${VFLAGS} --top-module simulator -I${CMAKE_CURRENT_SOURCE_DIR}/../tv80/rtl/core -I${CMAKE_CURRENT_SOURCE_DIR}/uart -I${CMAKE_CURRENT_SOURCE_DIR}/.. -I${CMAKE_CURRENT_SOURCE_DIR}/ -Wno-fatal -cc simulator.v
                  )

add_custom_target(Verilated ALL COMMAND verilator -CFLAGS "-fPIC" ${VFLAGS} --top-module simulator -I${CMAKE_CURRENT_SOURCE_DIR}/../tv80/rtl/core -I${CMAKE_CURRENT_SOURCE_DIR}/uart -I${CMAKE_CURRENT_SOURCE_DIR}/.. -I${CMAKE_CURRENT_SOURCE_DIR}/ -Wno-fatal -cc simulator.v)
add_custom_target(Vsimulator ALL COMMAND make -C obj_dir -f Vsimulator.mk)

set(VERILATED_SOURCES ${VERILATOR_INCLUDE_DIR}/verilated.cpp ${VERILATOR_INCLUDE_DIR}/verilated_vcd_c.cpp)

add_library(zebusim SHARED targets/zebusim/zebusim.cpp ${SIMLIB_HEADERS} ${SIMLIB_SOURCES}  ${CMAKE_CURRENT_BINARY_DIR}/obj_dir/Vsimulator.h ${CMAKE_CURRENT_BINARY_DIR}/obj_dir/Vsimulator.cpp ${VERILATED_SOURCES})
target_include_directories(zebusim PUBLIC . ${VERILATOR_INCLUDE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/obj_dir)
target_link_libraries(zebusim ${CMAKE_CURRENT_BINARY_DIR}/obj_dir/Vsimulator__ALL.a)

add_dependencies(Vsimulator Verilated)
add_dependencies(zebusim Vsimulator)

add_executable(simdrive simulator_driver_cli.cpp ${VERILATED_SOURCES} ${SIMLIB_HEADERS} ${SIMLIB_SOURCES})
target_include_directories(simdrive PUBLIC . ${VERILATOR_INCLUDE_DIR})
target_link_libraries(simdrive dl)