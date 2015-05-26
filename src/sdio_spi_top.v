`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:53:53 05/22/2015 
// Design Name: 
// Module Name:    spi_slave_top 
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
module sdio_spi_top(
		rst, clk, SCK, MOSI, MISO, SSEL
    );

input rst;
input clk;
input SCK, SSEL, MOSI;
output MISO;

parameter true = 1'b0, false = 1'b1;

wire [7:0] spi_data_o, spi_data_i;
wire spi_txcomp;
wire spi_rxdy;

SPI_slave spi_slave_inst(.rst(rst), 
						.clk(clk), 
						.SCK(SCK), 
						.MOSI(MOSI), 
						.MISO(MISO), 
						.SSEL(SSEL), 
						.spi_data_i(spi_data_i), 
						.spi_txcomp(spi_txcomp), 
						.spi_data_o(spi_data_o), 
						.spi_rxdy(spi_rxdy)
						);

wire [7:0] txdat;
wire txen, rdrxd, txfull, txempty;
reg rdfifo = false;
//wire rdfifo;

//assign rdfifo = spi_txcomp;

assign txen = spi_rxdy;

assign spi_data_i = txdat;

fifo_mxn #(8, 6) rxfifo(
		.rst(rst),
		.clk(clk),
		.ien(txen),
		.oen(rdfifo),
		.idat(spi_data_o),
		.odat(txdat),
		.full(txfull),
		.empty(txempty)
		);

reg spi_rxdy_buf = 1'b0;
reg spi_txcomp_buf = 1'b0;
wire negedge_spi_rxdy = spi_rxdy_buf & ~spi_rxdy;
wire negedge_spi_txcomp = spi_txcomp_buf & ~spi_txcomp;
always @ (posedge clk or negedge rst)
begin 
	if(rst == 1'b0)
		begin //reset
			spi_rxdy_buf <= 1'b0;
			spi_txcomp_buf <= 1'b0;
		end
	else
		begin //buffer
			spi_rxdy_buf <= spi_rxdy;
			spi_txcomp_buf <= spi_txcomp;
		end
end
		
reg [3:0] read_stat = 4'b0;
always @(posedge clk)
	begin
		if(~rst)
			begin
				rdfifo <= false;
			end
		else
			begin
				case(read_stat)
					0:begin
						if(txempty == false && spi_txcomp_buf)
							begin
								read_stat <= 3'b1;
								rdfifo <= true;
							end
					end
					1:begin
						read_stat <= 3'b0;
						rdfifo <= false;
					end
					default:begin
						read_stat <= 3'b0;
						rdfifo <= false;
					end
				endcase
			end
	end

endmodule
