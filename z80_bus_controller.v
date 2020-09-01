`ifndef Z80_BUS_CONTROLLER_V
`define Z80_BUS_CONTROLLER_V 1

`include "z80_bus_controller_core.v"

module z80_bus_controller (
    input         i_reset_n,

    input         i_mclk,
    output        o_clk,

    input         i_m1_n,
    input   [7:0] i_addr,
    input         i_iorq_n,
    input         i_memrq_n,
    input         i_rd_n,
    input         i_wr_n,
    inout   [7:0] io_data,
    input   [1:0] i_page,
    inout   [7:0] io_uaddr,
	 
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

    wire [7:0] data_out;
    wire [7:0] uaddr_out;
    wire data_out_en;
    wire wait_n;
    wire int_n;

    assign io_data = data_out_en ? data_out : 8'bZZZZZZZZ;
    assign io_uaddr = i_busack_n ? uaddr_out : 8'bZZZZZZZZ;
    assign o_wait_n = wait_n ? 1'bZ : 1'b0;
    assign o_int_n = int_n ? 1'bZ : 1'b0;

    z80_bus_controller_core core(
        .i_reset_n(i_reset_n),
        .i_mclk(i_mclk),
        .o_clk(o_clk),
        .i_m1_n(i_m1_n),
        .i_addr(i_addr),
        .i_iorq_n(i_iorq_n),
        .i_memrq_n(i_memrq_n),
        .i_rd_n(i_rd_n),
        .i_wr_n(i_wr_n),
        .i_data(io_data),
        .o_data(data_out),
        .o_data_en(data_out_en),
        .i_page(i_page),
        .i_uaddr(io_uaddr),
        .o_uaddr(uaddr_out),
        .i_uart_inta(i_uart_inta),
        .i_uart_intb(i_uart_intb),
        .o_int_n(int_n),
        .i_busack_n(i_busack_n),
        .o_reset(o_reset),
        .o_wait_n(wait_n),
        .o_ram_cs_n(o_ram_cs_n),
        .o_rom_cs_n(o_rom_cs_n),
        .o_uart_cs_n(o_uart_cs_n),
        .o_iorq1_n(o_iorq1_n),
        .o_iorq2_n(o_iorq2_n),
        .o_iorq3_n(o_iorq3_n),
        .o_iorq4_n(o_iorq4_n),

        .o_sck(o_sck),
        .o_mosi(o_mosi),
        .i_miso(i_miso),
        .o_ssel(o_ssel)
    );
endmodule
`endif