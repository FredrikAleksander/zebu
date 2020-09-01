`include "z80_top_direct_n.v"
`include "z80_bus_controller.v"

module simulator;
    reg mclk = 1'b0;
    reg reset_n = 1'b1;

    wire sysclk;
    wire m1_n;
    wire mreq_n,
    wire iorq_n,
    wire rd_n,
    wire wr_n,
    wire rfsh_n,
    wire halt_n,
    wire busack_n,

    wire wait_n,
    wire int_n,
    wire nmi_n,
    wire busrq_n,

    wire [7:0] data;

    wire [13:0] cpu_addr;
    wire [1:0]  cpu_page;
    wire [7:0]  cpu_page_block;

    z80_top_direct_n cpu(
        .CLK(sysclk),
        .nM1(m1_n),
        .nMREQ(mreq_n),
        .nIORQ(iorq_n),
        .nRD(rd_n),
        .nWR(wr_n),
        .nRFSH(rfsh_n),
        .nHALT(halt_n),
        .nBUSACK(busack_n),
        .nWAIT(wait_n),
        .nINT(int_n),
        .nBUSRQ(busrq_n),
        .A({cpu_page, cpu_addr})
    );

    z80_bus_controller bus_controller(
        .i_addr(cpu_addr[7:0]),
        .io_uaddr()
    );


    wire [21:0] bus_address = busack_n ? 8'b00000000 :
        {cpu_page, cpu_addr};
endmodule