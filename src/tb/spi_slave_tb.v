`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:17:00 05/18/2015
// Design Name:   spi_slave
// Module Name:   D:/mywork/FPGA/project/spi_slave/src/tb/spi_slave_tb.v
// Project Name:  spi_slave
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: spi_slave
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module spi_slave_tb;

        // Inputs
        reg clk;
        reg rst;
        reg ssel;
        reg mosi;
        reg sck;
        //reg [7:0] spi_di;
        //reg spi_di_en;

        // Outputs
        wire miso;
        //wire [7:0] spi_do;
        //wire spi_do_en;
		  
		  wire [7:0] spi_data_i;
		  wire spi_txcomp; 
		  wire [7:0] spi_data_o;
		  wire spi_rxdy;

        // Instantiate the Unit Under Test (UUT)
        SPI_slave uut (
                .clk(clk), 
                .rst(rst), 
                .SSEL(ssel), 
                .MOSI(mosi), 
                .SCK(sck), 
                .MISO(miso),
					 .spi_data_i(spi_data_o), 
					 .spi_txcomp(spi_txcomp), 
					 .spi_data_o(spi_data_o), 
					 .spi_rxdy(spi_rxdy)
                //.spi_do(spi_do), 
                //.spi_do_en(spi_do_en), 
                //.spi_di(spi_do), 
                //.spi_di_en(spi_do_en)
        );

        initial begin
                // Initialize Inputs
                clk = 0;
                rst = 0;
                ssel = 1;
                mosi = 0;
                sck = 0;
                //spi_di = 0;
                //spi_di_en = 0;

                // Wait 100 ns for global reset to finish
                #100;
        
                // Add stimulus here
                rst = 1;
                
                #200;
                ssel = 0;
                
                #9000;
                ssel = 1;

        end
        
        always begin
                #325;
                forever begin
                        mosi = $random;
                        #25;
                        sck = 1;
                        #50;
                        sck = 0;
                        #25;
                end
        end
        
        
        
        always #5 clk=~clk;
      
endmodule

