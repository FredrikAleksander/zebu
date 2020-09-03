`ifndef FOOART_CORE_V
`define FOOART_CORE_V 1

// The fooart is not a UART, it is more like a parallel port, but is
// used in place of an UART until I get the time to write a 16550
// core. This is only used in the simulator for a fast way to get
// host communication working. The host simulator component has a very
// large transmit FIFO that contains data that is waiting to be read
// by the fooart. The fooart signals the host simulator when it is reading
// so the host simulator knows when to pop data from the FIFO. The
// host simulator captures transmissions from the fooart instantly, so no
// FIFO is required in that direction.
// I plan on making this act similarily to a 16450 later on, adding the
// LCR, MCR registers, divisor latch etc. Some functionality would do
// nothing, but would still set the internals as would be expected,
// interrupt as required etc. So it would be software compatible
module fooart_core(
    input        i_clk,
    input        i_reset,

    input        i_cs,
    input  [2:0] i_addr,
    input        i_rd,
    input        i_wr,

    input  [7:0] i_data,
    output [7:0] o_data,
    
    input  [7:0] i_rx,
    input        i_rx_available, // The simulator sets this to 1 when the FIFO has data
    output       o_rx_stb,       // This is 1 during reads from the port. This tells the simulator to pop a item from the FIFO when it goes back to 0

    output [7:0] o_tx,
    output       o_tx_stb,       // This is 1 during writes to the port. It tells the simulator to capture the data at o_tx

    output       o_int
);
    reg r_overrun_error   = 1'b0;
    reg r_parity_error    = 1'b0;
    reg r_framing_error   = 1'b0;
    reg r_break_interrupt = 1'b0;
    reg r_thr_empty       = 1'b1;
    reg r_dlab            = 1'b0;
    wire tx_empty         = r_thr_empty;

    wire [7:0] LSR = {1'b0, tx_empty, r_thr_empty, r_break_interrupt, r_framing_error, r_parity_error, r_overrun_error, i_rx_available };

    wire RBR_sel = i_addr == 3'b000 && r_dlab == 1'b0;
    wire THR_sel = RBR_sel;
    wire IER_sel = i_addr == 3'b001 && r_dlab == 1'b0;
    wire IIR_sel = i_addr == 3'b010;
    wire LCR_sel = i_addr == 3'b011;
    wire MCR_sel = i_addr == 3'b100;
    wire LSR_sel = i_addr == 3'b101;
    wire MSR_sel = i_addr == 3'b110;
    wire DLL_sel = i_addr == 3'b000 && r_dlab == 1'b1;
    wire DLM_sel = i_addr == 3'b000 && r_dlab == 1'b1;

    assign o_rx_stb = i_cs & i_rd & RBR_sel;
    assign o_tx_stb = i_cs & i_wr & THR_sel;
    assign o_tx     = o_tx_stb ? i_data : 8'hFF;

    
    assign o_data = ~(i_cs & i_rd) ? 8'h00 :
        (LSR_sel 
            ? LSR 
            : (RBR_sel
                ? i_rx
                : 8'h00));
    

    always @(posedge i_clk or posedge i_reset) begin
        if(i_reset) begin
            r_overrun_error <= 1'b0;
            r_parity_error <= 1'b0;
            r_framing_error <= 1'b0;
            r_break_interrupt <= 1'b0;
            r_thr_empty <= 1'b1;
            r_dlab <= 1'b0;
        end
    end
endmodule

`endif