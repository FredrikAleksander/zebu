`include "z80_top_direct_n.v"

module z80(
    output wire nM1,
    output wire nMREQ,
    output wire nIORQ,
    output wire nRD,
    output wire nWR,
    output wire nRFSH,
    output wire nHALT,
    output wire nBUSACK,

    input wire nWAIT,
    input wire nINT,
    input wire nNMI,
    input wire nRESET,
    input wire nBUSRQ,

    input wire CLK,
    output wire [15:0] A,
    input  [7:0] D,
    output [7:0] D_out,
    output       D_out_en
);
    wire driver_en = ~nWR;
    wire data = driver_en ? D_out : D;
    assign D_out_en = driver_en;
    

    z80_top_direct_n cpu(
        .CLK(CLK),
        .nM1(nM1),
        .nMREQ(nMEMRQ),
        .nIORQ(nIORQ),
        .nRD(nRD),
        .nWR(nWR),
        .nRFSH(nRFSH),
        .nHALT(nHALt),
        .nBUSACK(nBUSACK),
        .nWAIT(nWAIT),
        .nINT(nBUSRQ),
        .nBUSRQ(nBUSRQ),
        .A(A),
        .D(data)
    );

endmodule