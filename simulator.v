`include "tv80s.v"
`include "z80_bus_controller_core.v"
`include "sram.v"

module simulator(
    input i_reset,
    input i_clk
);
    wire reset_n = ~i_reset;

    wire sysclk;
    wire m1_n;
    wire mreq_n;
    wire iorq_n;
    wire rd_n;
    wire wr_n;
    wire rfsh_n;
    wire halt_n;
    wire busack_n;

    wire wait_n;
    wire int_n;
    wire nmi_n = 1'b1;
    wire busrq_n = 1'b1;

    wire uart_inta = 1'b0;
    wire uart_intb = 1'b0;
    
    wire controller_int_n;
    wire controller_reset;
    wire controller_wait_n;

    assign int_n = controller_int_n;

    wire ram_cs_n;
    wire rom_cs_n;
    wire uart_cs_n;
    wire iorq1_n;
    wire iorq2_n;
    wire iorq3_n;
    wire iorq4_n;

    wire sck;
    wire mosi;
    wire miso = 1'b1;
    wire [3:0] ssel;

    wire [13:0] cpu_addr;
    wire [1:0]  cpu_page;
    wire [7:0]  cpu_page_block;

    wire [21:0] master_addr = {cpu_page_block, cpu_addr};
    wire [7:0] master_data_i;
    wire [7:0] master_data_o;

    tv80s cpu(
        .clk(sysclk),
        .reset_n(reset_n),
        .m1_n(m1_n),
        .wait_n(wait_n),
        .int_n(int_n),
        .nmi_n(nmi_n),
        .busrq_n(busrq_n),
        .mreq_n(mreq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .rfsh_n(rfsh_n),
        .halt_n(halt_n),
        .busak_n(busack_n),
        .A({cpu_page, cpu_addr}),
        .di(master_data_i),
        .dout(master_data_o)
    );

    wire [7:0] controller_data;
    wire controller_data_en;

    z80_bus_controller_core core(
        .i_reset_n(reset_n),
        .i_mclk(~i_clk),
        .o_clk(sysclk),
        .i_m1_n(m1_n),
        .i_addr(cpu_addr[7:0]),
        .i_iorq_n(iorq_n),
        .i_memrq_n(mreq_n),
        .i_rd_n(rd_n),
        .i_wr_n(wr_n),
        .i_data(master_data_o),
        .o_data(controller_data),
        .o_data_en(controller_data_en),
        .i_page(cpu_page),
        .i_uaddr(cpu_page_block),
        .o_uaddr(cpu_page_block),
        .i_uart_inta(uart_inta),
        .i_uart_intb(uart_intb),
        .o_int_n(controller_int_n),
        .i_busack_n(busack_n),
        .o_reset(controller_reset),
        .o_wait_n(controller_wait_n),
        .o_ram_cs_n(ram_cs_n),
        .o_rom_cs_n(rom_cs_n),
        .o_uart_cs_n(uart_cs_n),
        .o_iorq1_n(iorq1_n),
        .o_iorq2_n(iorq2_n),
        .o_iorq3_n(iorq3_n),
        .o_iorq4_n(iorq4_n),

        .o_sck(sck),
        .o_mosi(mosi),
        .i_miso(miso),
        .o_ssel(ssel)
    );

    assign wait_n = controller_wait_n;

    wire [7:0] ram_data_i;
    wire [7:0] ram_data_o;
    sram ram(
        .i_reset(i_reset),
        .i_clk(sysclk),
        .i_cs_n(ram_cs_n),
        .i_wr_n(wr_n),
        .i_addr(master_addr[18:0]),
        .i_data(ram_data_i),
        .o_data(ram_data_o)
    );

    wire [7:0] rom_data_o;
    rom _rom(
        .i_addr(master_addr[18:0]),
        .o_data(rom_data_o)
    );
    
    assign master_data_i = controller_data_en ?
        controller_data : (~(ram_cs_n | rd_n) ? ram_data_o : (~(rom_cs_n | rd_n) ? rom_data_o : 8'bZZZZZZZZ));
endmodule