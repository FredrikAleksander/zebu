`ifndef Z80_MMU_V
`define Z80_MMU_V 1

module z80_mmu(
	input        i_reset,
	input        i_clk,
	
   input        i_cs_n,
   input        i_wr_n,
   input  [1:0] i_addr,
   input  [7:0] i_data,
   output [7:0] o_data,

   input  [1:0] i_page,
   output [7:0] o_block
);

	reg [7:0] slots [0:3];

   assign o_block = slots[i_page];
   assign o_data  = slots[i_addr];

   initial
   begin
       slots[0] = 8'b11100000;
       slots[1] = 8'b11000000;
       slots[2] = 8'b11000001;
       slots[3] = 8'b11000011;
   end

   always @(posedge i_clk or posedge i_reset)
   begin
       if(i_reset) begin
          slots[0] <= 8'b11100000;
			 slots[1] <= 8'b11000000;
			 slots[2] <= 8'b11000001;
			 slots[3] <= 8'b11000011;
       end
       else if(~(i_cs_n|i_wr_n))
           slots[i_addr] <= i_data;
   end
endmodule

`endif