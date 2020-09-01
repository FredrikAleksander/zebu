`timescale 1ns / 1ps
`ifndef CONFIG_REGISTER_V
`define CONFIG_REGISTER_V 1
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:45:12 06/15/2013 
// Design Name: 
// Module Name:    config_register 
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
// Configuration registers for SPI interface.
//
//////////////////////////////////////////////////////////////////////////////////
module config_register(
    input reset,
    input clk,
    input wr_L,
    input config_select,
    input serclk_polarity_in,
    output serclk_polarity_out,
    output serclk_polarity_bus_out,
         input [3:0] serclk_speed_in,
         output [3:0] serclk_speed_out,
         output [3:0] serclk_speed_bus_out,
         input set_inhibit
    );

        reg serclk_polarity;
        reg [3:0] serclk_speed;
        
        assign serclk_polarity_out=serclk_polarity;
        assign serclk_polarity_bus_out=serclk_polarity ;
        
        assign serclk_speed_out=serclk_speed;
        assign serclk_speed_bus_out=serclk_speed;

        initial begin
                serclk_polarity = 0;
                serclk_speed = 0;
        end
        
        // Note the FF only gets set if data D5 is low.
        // D5 high signals to start reading from the SPI device.
        always @(posedge clk or posedge reset)
        begin
                if(reset)
                begin
                        serclk_polarity <= 0;
                        serclk_speed <= 0;
                end
                else if(!(wr_L | config_select | set_inhibit))
                begin
                        serclk_polarity <= serclk_polarity_in;
                        serclk_speed <= serclk_speed_in;
                end
        end

endmodule
`endif