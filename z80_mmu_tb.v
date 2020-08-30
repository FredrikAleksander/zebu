`timescale 1ns/1ps

`include "z80_mmu.v"

module z80_mmu_tb;
    // Verify that the MMU translates virtual addresses
    // the way it is programmed to

    reg reset;
    reg clk;

    reg cs_n;
    reg wr_n;
    reg [15:0] cycle;
    reg [1:0] addr;
    reg [7:0] data;
    reg [1:0] page;
    
    wire [7:0] data_output;
    wire [7:0] block;

    z80_mmu mmu(
        .i_reset(reset),
        .i_clk(~clk),
        .i_cs_n(cs_n),
        .i_wr_n(wr_n),
        .i_addr(addr),
        .i_data(data),
        .i_page(page),
        .o_block(block),
        .o_data(data_output)
    );

    initial
    begin
        $dumpfile("z80_mmu_tb.vcd");
        $dumpvars(0, z80_mmu_tb);

        reset <= 1'b0;
        clk <= 1'b1;
        cs_n <= 1'b1;
        wr_n <= 1'b1;
        page <= 2'b00;
        addr <= 2'b00;
        data <= 8'bZZZZZZZZ;

        // Write block 0xDE to page 0
        @(posedge clk);
        cycle <= "T1";
        cs_n <= 1'b1;
        wr_n <= 1'b1;
        page <= 2'b00;
        addr <= 2'b00;
        @(negedge clk)
        data <= 8'hDE;
        
        @(posedge clk);
        cycle <= "T2";
        cs_n <= 1'b0;
        wr_n <= 1'b0;
        addr <= 2'b00;

        @(posedge clk);
        cycle <= "TW";
        @(posedge clk);
        cycle <= "T3";
        @(negedge clk);
        cs_n <= 1'b1;
        wr_n <= 1'b1;
        data <= 0;

        @(posedge clk);
        cycle <= "..";
        data <= 8'bZZZZZZZZ;

        #312.500;

        assert (block == 8'hDE) else $display("MMU translation failed");

        #1000;

        $finish;
    end

    always 
    begin
        clk = 1'b1;
        #31.250; // high for 31.250 * timescale = 31.25ns

        clk = 1'b0;
        #31.250; // low for 31.250 * timescale = 31.25 ns
    end
endmodule