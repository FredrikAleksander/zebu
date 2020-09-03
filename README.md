ZEBU
===========================

Project files for a Z80 Bus Controller that contains a MMU, programmable wait-state generator and
SPI master. Designed to be used with a MAX7000S CPLD (EPM7128SCL84).

The bus controller implements all glue logic required to build a extendable Z80 homebrew computer.
The controller support a Plug and Play system, inspired by Amiga Autoconfig and the ISA Plug and Play standard

Features
---------------------
* 16Mhz operation from 32Mhz input clock
* Plug and Play support
* 4MB Address Space with a MMU for the CPU
* 4 Expansion devices (each device may contain multiple child devices, handled by the parent device)
* Programmable wait-state generator allows inserting up to 2 wait-states pr expansion device
* Builtin memory decoder
* Builtin I/O decoder


Requirements:
---------------------
* Quartus 13.0sp1 (only needed for programming CPLD)
* Icarus Verilog (for compiling testbenches)
* GTKWave (for viewing testbench waveform data)

Plug and Play
---------------------
The bus controller contains a SPI master with 4 slave selects, each connected to a expansion device connector. Expansion devices may connect a 25LCxxx SPI EEPROM to this master, and the BIOS will read the device information (vendor, device and function code, number of wait-states required, and any optional driver code) at system startup and configure the device automatically. It is possible to program the SPI EEPROMs from the sytem while it is running for bootstrapping new devices

MMU
---------------------
The system bus is 22 bits (4MB), and any additional busmasters
should address the entire 22 bits directly. The Z80 CPU however
only has a 64KB address space, so the bus controller implements
a MMU for the CPU to use to access memory on the bus.

The bus controller does decoding of the top 1MB of the address space, providing active-low chip selects for 512KB RAM and 512KB ROM. The lower 3MB of the address space is left for any
memory expansion devices.

I/O Decoder
---------------------
The upper 128 I/O addresses are reserved for use by the bus
controller. The lower 128 I/O addresses are provided for
expansion devices. Each expansion device is given 32 addresses,
and the bus controller will do address decoding, providing 4
chip selects (`IORQ1`, `IORQ2`, `IORQ3`, `IORQ4`). A chip select
for a UART is available.


Programmable Wait-State Generator
---------------------
To facilitate interfacing with devices that require slow access times, the bus controller contains a programmable wait-state generator that supports inserting up to 2 wait states for each expansion device. The wait stage generator has 4x 2-bit registers for storing the number of wait states. Only expansion devices that are using the I/O decoder chip selects may have wait-states inserted (no wait-state for memory). Devices may provide the required number of wait states in their device information to allow automatically configuring this at system startup.

Memory Map
---------------------
`0x000000 Expansion Memory`

`0x300000 RAM`

`0x380000 ROM`

I/O Device Map
---------------------
`0x00 Expansion Device #1 (IORQ1)`

`0x20 Expansion Device #2 (IORQ2)`

`0x40 Expansion Device #3 (IORQ3)`

`0x60 Expansion Device #4 (IORQ4)`

`0x80 UART`

`0xA0 SPI Master`

    +0x00 DATA    (R/W)
    +0x01 CTRL    (R/W)

`0xC0 Programmable Wait-State Generator`

    +0x00 DEVCFG1 (R/W)
    +0x01 DEVCFG2 (R/W)
    +0x02 DEVCFG3 (R/W)
    +0x03 DEVCFG4 (R/W)

`0xE0 MMU`

    +0x00 PAGE0   (R/W)
    +0x01 PAGE1   (R/W)
    +0x02 PAGE2   (R/W)
    +0x03 PAGE3   (R/W)

Simulation
-------------------------

It is possible to compile a fully functional system simulator using Verilator.
The simulator can be provided with the filename of a ROM to use and optionally
the path to a trace file (VCD) that may be used to analyze the signals generated
under simulation in a tool like GtkWave. I plan on extending this simulator
more in the future to support UART communication with the host, aswell
as video output