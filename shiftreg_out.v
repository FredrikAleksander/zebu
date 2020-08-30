`timescale 1ns / 1ps
`ifndef SHIFTREG_OUT_V
`define SHIFTREG_OUT_V 1
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dylan Smith
// 
// Create Date:    19:37:03 06/14/2013 
// Design Name: 
// Module Name:    shiftreg_out 
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
// Double buffered parallel to serial converter with independent clocks for
// input register and output serial stream.
//
//////////////////////////////////////////////////////////////////////////////////
module shiftreg_out(
    input serial_clk,
    output serial_out,
         output busy,
         input reset,
    input set_enable,
    input set_clk,
    input [7:0] data_in
    );
         
         reg [7:0] data;
         reg [7:0] shift_data;
         reg [3:0] current_bit;
         reg vreg;
         wire valid;
         
         reg sending;
         assign busy = sending & vreg;
         
         assign serial_out=busy ? shift_data[7] : 1'b1;
         
         wire ser_reset;
         assign ser_reset=!set_enable | reset;
         
         wire data_done;
         assign data_done=current_bit[3];
         
         // data is valid once the FF is set and enable
         // has returned high.
         assign valid = vreg & set_enable;

         initial begin
                 data <= 0;
                 shift_data <= 0;
                 current_bit <= 0;
                 vreg <= 0;
                 sending <= 0;
         end

        always @(posedge set_clk or posedge reset or posedge data_done)
        begin
                if(reset)
                begin
                        data <= 0;
                        vreg <= 0;
                end
                else if(data_done)
                begin
                        vreg <= 0;
                end
                else if(!set_enable)
                begin
                        data <= data_in;
                        vreg <= 1;
                end
        end
        
        always @(posedge serial_clk or posedge ser_reset)
        begin
                if(ser_reset)
                begin
                        current_bit <= 0;
                        sending <= 0;
                end
                else if(valid)
                begin
                        if(!sending)
                        begin
                                shift_data <= data;
                                sending <= 1;
                        end
                        else
                        begin
                                if(!data_done)
                                begin
                                        shift_data <= shift_data << 1;
                                        current_bit <= current_bit + 4'b0001;
                                end
                        end
                end
        end
endmodule
`endif