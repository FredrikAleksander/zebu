`timescale 1ns / 1ps
`ifndef SERCLK_GENERATOR_V
`define SERCLK_GENERATOR_V 1
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:18:02 06/15/2013 
// Design Name: 
// Module Name:    serclk_generator 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module serclk_generator(
         input reset,
    input clk,
    input [3:0] speed_select,
    output clkout
    );

        // Clock divider.
        reg [7:0] divider;
        assign clkout=speed_select[3] ? divider[speed_select[2:0]] : clk;

        initial begin
                divider = 0;
        end

        // Increment clock divider with each Z80 clock cycle.                   
        always @(posedge clk or posedge reset)
        begin
                if(reset)
                        divider <= 0;
                else
                        divider <= divider + 8'b00000001;
        end
                                                                                                        
endmodule
`endif