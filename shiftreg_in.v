`timescale 1ns / 1ps
`ifndef SHIFTREG_IN_V
`define SHIFTREG_IN_V 1
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:25:29 06/15/2013 
// Design Name: 
// Module Name:    shiftreg_in 
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
// Read incoming serial data. The expectation is that this is driven by
// the serial write (which holds all the state information for how far we've
// got in the byte etc)
//
//////////////////////////////////////////////////////////////////////////////////
module shiftreg_in(
    input reset,
    output [7:0] data,
			input serclk,
         input ser_in,
         input enable                   // active high
    );
         
         reg [7:0] shiftreg;
         assign data = shiftreg;
         wire inv_serclk;
         assign inv_serclk=!serclk;

         initial begin
                 shiftreg <= 0;
         end
         
        always @(posedge inv_serclk or posedge reset)
        begin
                if(reset)
                        shiftreg <= 0;
                else if(enable)
                        shiftreg <= { shiftreg[6:0], ser_in };
        end

endmodule
`endif