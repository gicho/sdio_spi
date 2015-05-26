`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   09:48:43 05/26/2015
// Design Name:   sdio_spi_top
// Module Name:   D:/mywork/FPGA/project/sdio_spi/src/tb/sdio_spi_top_tb.v
// Project Name:  sdio_spi
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: sdio_spi_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module sdio_spi_top_tb;

	// Inputs
	reg rst;
	reg clk;
	reg SCK;
	reg MOSI;
	reg SSEL;

	// Outputs
	wire MISO;

	// Instantiate the Unit Under Test (UUT)
	sdio_spi_top uut (
		.rst(rst), 
		.clk(clk), 
		.SCK(SCK), 
		.MOSI(MOSI), 
		.MISO(MISO), 
		.SSEL(SSEL)
	);

	initial begin
		// Initialize Inputs
		rst = 0;
		clk = 0;
		SCK = 0;
		MOSI = 0;
		SSEL = 1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		rst = 1;
		
		#200;
		SSEL = 0;
		
		#20000;
		SSEL = 1;

	end
	
	always 
		begin
			#325;
			forever 
				begin
					MOSI = $random;
					#25;
					SCK = 1;
					#50;
					SCK = 0;
					#25;
				end
        end
        
        
        
	always #5 clk=~clk;
      
endmodule

