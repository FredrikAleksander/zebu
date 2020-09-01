`ifndef ROM_V
`define ROM_V 1

module rom(
    input [18:0] i_addr,
    output [7:0] o_data
);
    reg [7:0] memory [0:524287];

    assign o_data = memory[i_addr];
endmodule

`endif