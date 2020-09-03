`timescale 1ns/1ps
`include "z80_waitstate_generator.v"

module z80_waitstate_generator_tb;
    // Verify that wait state generator inserts the
    // programmed number of wait-states
    reg reset;
    reg clk;

    //reg cs_n;
    reg wr_n;
    

    reg [15:0] cycle;
    reg [7:0] addr;
    reg [7:0] data;

    reg iorq_n;
    wire cs_n = (addr[7:5] != 3'b110) | iorq_n;
    wire wiorq_n = addr[7] | iorq_n;

    wire r_wait_n;

    z80_waitstate_generator wsg(
        .i_reset(reset),
        .i_clk(clk),
        .i_iorq_n(wiorq_n),
        .i_device(addr[6:5]),
        .i_cs_n(cs_n),
        .i_wr_n(wr_n),
        .i_addr(addr[1:0]),
        .i_data(data),
        .o_wait_n(r_wait_n)
    );

    initial
    begin
        $dumpfile("z80_waitstate_generator_tb.vcd");
        $dumpvars(0, z80_waitstate_generator_tb);

        reset <= 1'b0;
        clk <= 1'b1;
        wr_n <= 1'b1;
        iorq_n <= 1'b1;
        data <= 8'bZZZZZZZZ;

        // Set device 1 to use 2 wait-states
        @(posedge clk);
        cycle <= "T1";
        wr_n <= 1'b1;
        addr <= 8'b11000000;
        @(negedge clk);
        data <= 8'b00000011;
        
        @(posedge clk);
        cycle <= "T2";

        iorq_n <= 1'b0;
        wr_n <= 1'b0;

        @(posedge clk);
        cycle <= "TW";
        @(posedge clk);
        cycle <= "T3";
        @(negedge clk);
        iorq_n <= 1'b1;
        wr_n <= 1'b1;

        // Make I/O write cycle to device 1, ensure 2 wait states are inserted

        @(posedge clk);
        cycle <= "T1";
        wr_n <= 1'b1;
        addr <= 8'b00000000;
        data <= 8'bZZZZZZZZ;
        @(negedge clk);
        data <= 8'b00000011;
        
        @(posedge clk);
        cycle <= "T2";

        iorq_n <= 1'b0;

        wr_n <= 1'b0;

        @(posedge clk);
        cycle <= "W1";

        #0.10 assert (r_wait_n == 1'b0) else $display("Wait-State missing");

        @(posedge clk);
        cycle <= "W2";

        #0.10 assert (r_wait_n == 1'b0) else $display("Wait-State missing");

        @(posedge clk);
        cycle <= "W3";

        #0.10 assert (r_wait_n == 1'b1) else $display("Wait-States overextended");

        @(posedge clk);
        cycle <= "T3";
        @(negedge clk);
        iorq_n <= 1'b1;
        wr_n <= 1'b1;

        @(posedge clk);
        data <= 8'bZZZZZZZZ;

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