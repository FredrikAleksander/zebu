`ifndef Z80_WAITSTATE_GENERATOR_V
`define Z80_WAITSTATE_GENERATOR_V

module z80_waitstate_generator(
    input        i_reset,
    input        i_clk,
    input        i_cs_n,
    input        i_wr_n,
    input  [1:0] i_addr,
    input  [7:0] i_data,
    input        i_iorq_n,
    input  [1:0] i_device,
    output [7:0] o_data,
    output       o_wait
);
    reg [1:0] dev_waitstates [0:3];
    wire [1:0] waitstates = dev_waitstates[i_device];

    reg [1:0] bits = 2'b00;             // Bits for shift register
    reg  lrq_n     = 1'b1;              // Value of i_rq_n during the last clock cycle
    wire trig      = ~i_iorq_n & lrq_n; // Active High first cycle of a request

    wire w2 = waitstates[1];
    wire w1 = waitstates[0] | w2;

    assign o_data = {6'b000000, dev_waitstates[i_addr[1:0]]};

    assign o_wait = ~(i_iorq_n | ~bits[1]);

    initial begin
        dev_waitstates[0] <= 2'b00;
        dev_waitstates[1] <= 2'b00;
        dev_waitstates[2] <= 2'b00;
        dev_waitstates[3] <= 2'b00;
    end

    always @(posedge i_clk or posedge i_reset)
    begin
        if(i_reset) begin
            lrq_n <= 1'b1;
            dev_waitstates[0] <= 2'b00;
            dev_waitstates[1] <= 2'b00;
            dev_waitstates[2] <= 2'b00;
            dev_waitstates[3] <= 2'b00;
        end
        else begin
            lrq_n <= i_iorq_n;

            if(trig)
                bits <= { w1, w2 };
            else begin
                bits[1] <= bits[0];
                bits[0] <= 1'b0;
            end

            if(~(i_cs_n | i_wr_n)) begin
                dev_waitstates[i_addr] <= i_data[1:0];
            end
        end
    end
endmodule

`endif