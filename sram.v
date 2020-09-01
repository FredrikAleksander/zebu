`ifndef SRAM_V
`define SRAM_V 1

module sram(
    input        i_reset,
    input        i_clk,
    input        i_cs_n,
    input        i_wr_n,
    input [18:0] i_addr,
    input  [7:0] i_data,
    output [7:0] o_data
);
    reg [7:0] memory [0:524287];

    assign o_data = memory[i_addr];

    always @(posedge i_clk or posedge i_reset) begin
        if(i_reset) begin
        end
        else if(~(i_cs_n | i_wr_n))
            memory[i_addr] <= i_data;
    end
endmodule

`endif