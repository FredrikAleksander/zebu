`timescale 1ns / 1ps
`ifndef Z80_SPIMASTER_V
`define Z80_SPIMASTER_V

`include "config_register.v"
`include "serclk_generator.v"
`include "shiftreg_in.v"
`include "shiftreg_out.v"

module z80_spimaster(
    input reset,
    input clk,
    input rd_L,
    input wr_L,
    
    input iorq_L,

    input a,
    input [7:0] d,
    output [7:0] d_out,
    output spi_clk,
    output mosi,
    input miso,
    output [3:0] spi_cs
         
    );
        wire [7:0] config_data;
        wire [7:0] spi_data;

        wire spi_select;                        // IORQ for SPI write or read
        wire spi_write;                 // IORQ for SPI write
        wire config_select;             // IORQ for config read or write
        wire [3:0] serclk_speed;        // Speed of SPI clock
        wire serclk_polarity;   // SPI clock polarity
        wire serclk;                            // serial clock
        wire spi_writing;                       // 1 = currently reading SPI
        //wire spi_start_read;            // Signal start reading from SPI.
        reg [1:0] spi_cs_reg;   // SPI chip selects
        reg spi_cs_hold;
        wire [3:0] spi_cs_demuxed;              // SPI chip selects demultiplexed: active low

        assign d_out = config_select ? spi_data : config_data;
        
        assign spi_write=spi_select | wr_L;             // Active low
        assign spi_cs=(spi_writing | spi_cs_hold) ? spi_cs_demuxed : 4'b1111;

        assign config_data[7]=spi_writing;
        assign config_data[6:5]=spi_cs_reg;

        assign spi_clk=serclk_polarity ? serclk | !spi_writing : !serclk & spi_writing;
        //assign spi_start_read=config_select | wr_L | !d[5];
        
        assign spi_cs_demuxed = (spi_cs_reg==2'b00) ? 4'b1110 :
                                (spi_cs_reg==2'b01) ? 4'b1101 :
                                                                        (spi_cs_reg==2'b10) ? 4'b1011 :
                                                                                              4'b0111;

        initial begin
                spi_cs_reg <= 0;
                spi_cs_hold <= 1'b0;
        end

        always @(posedge clk or posedge reset)
        begin
                if(reset) begin
                        spi_cs_reg <= 0;
                        spi_cs_hold <= 1'b0;
                end
                else if(!(config_select | wr_L)) begin
                        spi_cs_reg <= d[6:5];
                        spi_cs_hold <= d[7];
                end
        end

        assign spi_select = (a | iorq_L);
        assign config_select = (~a | iorq_L);
                
        config_register cfg (
                .reset(reset),
                .clk(clk),
                .wr_L(wr_L),
                .config_select(config_select),
                .serclk_polarity_in(d[0]),
                .serclk_speed_in(d[4:1]),
                .serclk_polarity_bus_out(config_data[0]),
                .serclk_speed_bus_out(config_data[4:1]),
                .serclk_polarity_out(serclk_polarity),
                .serclk_speed_out(serclk_speed),
                .set_inhibit(config_data[5]));
                
        serclk_generator sgen (
                .reset(reset),
                .clk(clk),
                .speed_select(serclk_speed),
                .clkout(serclk));
                
        shiftreg_out sout (
                .reset(reset),
                .set_clk(clk),
                .set_enable(spi_write),
                .busy(spi_writing),
                .data_in(d),
                .serial_clk(serclk),
                .serial_out(mosi));
                
        // reads always happen simultaneously to a write so the
        // spi_writing indicator makes us read, too.
        shiftreg_in sin (
                .reset(reset),
                .data(spi_data),
                .enable(spi_writing),
                .serclk(serclk),
                .ser_in(miso));
endmodule
`endif