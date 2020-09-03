`timescale 1ns / 1ps
`include "z80_spimaster.v"

module z80_spimaster_tb;
    // Verify that the SPI master can properly interface
    // with a SPI device
    reg reset;
    reg clk;

    reg cs_n;
    reg wr_n;
    reg rd_n;

    reg [15:0] cycle;
    reg addr;
    reg [7:0] data;

    wire [3:0] ssel;
    wire       sck;
    wire       mosi;
    reg        miso;
    wire [7:0] data_output;

    z80_spimaster spimaster(
        .reset(reset),
        .clk(~clk),
        .rd_L(rd_n),
        .wr_L(wr_n),
        .iorq_L(cs_n),
        .a(addr),
        .d(data),
        .d_out(data_output),
        .spi_clk(sck),
        .mosi(mosi),
        .miso(miso),
        .spi_cs(ssel)
    );

    initial
    begin
        $dumpfile("z80_spimaster_tb.vcd");
        $dumpvars(0, z80_spimaster_tb);

        reset <= 1'b0;
        clk <= 1'b1;
        wr_n <= 1'b1;
        rd_n <= 1'b1;
        cs_n <= 1'b1;
        addr <= 1'b0;
        miso <= 1'b1;
        data <= 8'bZZZZZZZZ;

        // Write byte 0x55
        @(posedge clk);
        cycle <= "T1";
        wr_n <= 1'b1;
        addr <= 1'b0;
        @(negedge clk);
        data <= 8'h55;
        
        @(posedge clk);
        cycle <= "T2";
        cs_n <= 1'b0;
        wr_n <= 1'b0;

        @(posedge clk);
        cycle <= "TW";
        @(posedge clk);
        cycle <= "T3";
        @(negedge clk);
        cs_n <= 1'b1;
        wr_n <= 1'b1;

        repeat(8) @(posedge clk);

        // Write byte 0x55
        @(posedge clk);
        cycle <= "T1";
        wr_n <= 1'b1;
        addr <= 1'b0;
        @(negedge clk);
        data <= 8'h55;
        
        @(posedge clk);
        cycle <= "T2";
        cs_n <= 1'b0;
        wr_n <= 1'b0;

        @(posedge clk);
        cycle <= "TW";
        @(posedge clk);
        cycle <= "T3";
        @(negedge clk);
        cs_n <= 1'b1;
        wr_n <= 1'b1;

        #10000
        $finish;
    end

    always 
    begin
        clk = 1'b1;
        #31.250; // high for 31.250 * timescale = 31.25ns

        clk = 1'b0;
        #31.250; // low for 31.250 * timescale = 31.25 ns

        miso <= ~miso;
    end
endmodule