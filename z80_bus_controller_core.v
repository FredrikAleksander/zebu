`ifndef Z80_BUS_CONTROLLER_CORE_V
`define Z80_BUS_CONTROLLER_CORE_V 1

`include "z80_mmu.v"
`include "z80_spimaster.v"
`include "z80_waitstate_generator.v"

module z80_bus_controller_core (
    input         i_reset_n,

    input         i_mclk,
    output        o_clk,

    input         i_m1_n,
    input   [7:0] i_addr,
    input         i_iorq_n,
    input         i_memrq_n,
    input         i_rd_n,
    input         i_wr_n,
	 input   [7:0] i_data,
	 output  [7:0] o_data,
    output        o_data_en,
    input   [1:0] i_page,
    input   [7:0] i_uaddr,
    output  [7:0] o_uaddr,
	 
    input         i_uart_inta,
    input         i_uart_intb,
	 
    output        o_int_n,
    input         i_busack_n,
    output        o_reset,
    output        o_wait_n,

    output        o_ram_cs_n,
    output        o_rom_cs_n,
    output        o_uart_cs_n,

    output        o_iorq1_n,
    output        o_iorq2_n,
    output        o_iorq3_n,
    output        o_iorq4_n,

    output        o_sck,
    output        o_mosi,
    input         i_miso,
    output [3:0]  o_ssel
);
    // Clock divider
    reg clk2x = 1'b1;
    always @(posedge i_mclk)
        clk2x <= ~clk2x;

    wire sys_clk = clk2x;
    wire inv_clk = ~sys_clk;
    assign o_clk = sys_clk;

    // I/O Decoding
    wire iorq_n = i_iorq_n | ~i_m1_n;

    wire iorq1_sel_n = i_addr[7:5] != 3'b000; // I/O Address: 0x00 (Device #1)
    wire iorq2_sel_n = i_addr[7:5] != 3'b001; // I/O Address: 0x20 (Device #2)
    wire iorq3_sel_n = i_addr[7:5] != 3'b010; // I/O Address: 0x40 (Device #3)
    wire iorq4_sel_n = i_addr[7:5] != 3'b011; // I/O Address: 0x60 (Device #4)

    wire uart_sel_n = i_addr[7:5] != 3'b100;  // I/O Address: 0x80 (UART)
    wire spi_sel_n  = i_addr[7:5] != 3'b101;  // I/O Address: 0xA0 (SPI Master)
    wire wsg_sel_n  = i_addr[7:5] != 3'b110;  // I/O Address: 0xC0 (Wait-State Generator)
    wire mmu_sel_n  = i_addr[7:5] != 3'b111;  // I/O Address: 0xE0 (Memory Management Unit)

    assign o_iorq1_n   = iorq1_sel_n | iorq_n;
    assign o_iorq2_n   = iorq2_sel_n | iorq_n;
    assign o_iorq3_n   = iorq3_sel_n | iorq_n;
    assign o_iorq4_n   = iorq4_sel_n | iorq_n;
    assign o_uart_cs_n = uart_sel_n  | iorq_n;

    wire spi_cs_n = spi_sel_n | iorq_n;
    wire wsg_cs_n = wsg_sel_n | iorq_n;
    wire mmu_cs_n = mmu_sel_n | iorq_n;

    // Data multiplexing
    wire [7:0] spi_data_o;
    wire [7:0] mmu_data_o;
    wire [7:0] mmu_uaddr_o;
    wire [7:0] uaddr_i;
	 
    wire [7:0] data_o = (mmu_sel_n ? (spi_sel_n ?  8'b00000000 : spi_data_o) : mmu_data_o);
	 
    assign o_data = data_o;
    assign o_data_en = ~(iorq_n | i_rd_n | (mmu_sel_n & spi_sel_n));

    //assign io_data = (wsg_cs_n | i_rd_n) ? ((mmu_cs_n | i_rd_n) ? ((spi_cs_n | i_rd_n) ? 8'bZZZZZZZZ : spi_data_o) : mmu_data_o) : wsg_data_o;
    wire [7:0] uaddr = i_busack_n ? mmu_uaddr_o : i_uaddr;
    assign o_uaddr = mmu_uaddr_o;

    wire reset = ~i_reset_n;
    assign o_reset = reset;

    // MMU
    z80_mmu mmu(
        .i_reset(reset),
        .i_clk(inv_clk),
        .i_cs_n(mmu_cs_n),
        .i_wr_n(i_wr_n),
        .i_addr(i_addr[1:0]),
        .i_data(i_data),
        .o_data(mmu_data_o),
        .i_page(i_page),
        .o_block(mmu_uaddr_o)
    );

    // SPI Master. Based on the zxspi project (http://spectrum.alioth.net/doc/index.php/ZX_SPI)
    z80_spimaster spimaster(
        .reset(reset),
        .clk(inv_clk),
        .rd_L(i_rd_n),
        .wr_L(i_wr_n),
        .iorq_L(spi_cs_n),
        .a(i_addr[0]),
        .d(i_data),
        .d_out(spi_data_o),
        .spi_clk(o_sck),
        .mosi(o_mosi),
        .miso(i_miso),
        .spi_cs(o_ssel)
    );

    // Memory Decoding. Top 512KB of address space is builtin ROM, the 512KB below that is builtin RAM.
    // The remaining lower 3MB of the address space can be used with a memory expansion card.
    wire ram_sel_n = uaddr[7:5] != 3'b110;
    wire rom_sel_n = uaddr[7:5] != 3'b111;

    assign o_ram_cs_n = ram_sel_n | i_memrq_n;
    assign o_rom_cs_n = rom_sel_n | i_memrq_n;

    // Programmable Wait-State Generator
    // All of the builtin components should support maximum clock
    // operation (16Mhz), so the wait state generator only needs
    // to work with expansion devices. Each device may have up to
    // 2 wait-states inserted pr cycle. Wait-states may not be
    // inserted for memory requests, so all memory expansions
    // should support 16 Mhz Z80 memory cycles (62.5*2=125ns access time)

    z80_waitstate_generator wsg(
        .i_reset(reset),
        .i_clk(sys_clk),
        .i_cs_n(wsg_cs_n),
        .i_wr_n(i_wr_n),
        .i_addr(i_addr[1:0]),
        .i_data(i_data),
        .i_iorq_n(i_addr[7] | iorq_n),
        .i_device(i_addr[6:5]),
        .o_wait_n(o_wait_n)
    );

    // Interrupts
    assign o_int_n = ~(i_uart_inta | i_uart_intb);
endmodule
`endif