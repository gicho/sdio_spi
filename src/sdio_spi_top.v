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
		rst, clk, SCK, MOSI, MISO, SSEL,
		sd_clk, cmd_i, finsh
    );

input rst;
input clk;
input SCK, SSEL, MOSI;
output MISO;
input sd_clk,
input cmd_i,
output finsh

parameter true = 1'b0, false = 1'b1;

/* registers define */
reg [7:0] SDIO_CTRL_REG;
reg [7:0] SDIO_FIFO_REG;

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
/* detect rxdy and txcomp signal edge */
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

wire txen, rdrxd, txfull, txempty, rxfull, rxempty;
reg [7:0] spi_tx_data;
assign spi_data_i = spi_tx_data;
wire [7:0] cmd_reg;
assign cmd_reg = spi_data_o;
reg [3:0] spi_state;
reg [3:0] read_stat = 4'b0;
reg rdfifo = false;
wire [7:0] txdat;

reg [7:0] txcount;
reg [7:0] cnt;

always @(posedge clk)
begin
	if(~rst)
		begin
			spi_state <= 4'b0;
			SDIO_CTRL_REG <= 8'h0;
			//SDIO_FIFO_REG <= 8'h0;
			spi_tx_data <= 8'h0;
			rdfifo <= false;
			read_stat <= 4'b0;
			txcount <= 8'b0;
			cnt <= 8'b0;
		end
	else
		begin
			case(spi_state)
				4'b0:begin
					if(negedge_spi_rxdy)
						begin
							case(cmd_reg)
								8'h02:begin
									spi_state <= 4'b1;
								end
								8'h03:begin
									spi_tx_data <= SDIO_CTRL_REG;
								end
								8'h04:begin
									spi_state <= 4'h2;
								end
								8'h05:begin
									spi_tx_data <= SDIO_FIFO_REG;
								end
								8'hcc:begin
									spi_state <= 4'h3;
								end
								default:begin
									spi_state <= 4'b0;
								end
							endcase
						end
				end
				4'b1:begin
					if(negedge_spi_rxdy)
						begin
							SDIO_CTRL_REG <= cmd_reg;
							spi_state <= 4'b0;
						end
				end
				4'h2:begin
					if(negedge_spi_rxdy)
						begin
							//SDIO_FIFO_REG <= cmd_reg;
							spi_state <= 4'b0;
						end
				end
				4'h3:begin
					if(negedge_spi_rxdy)
						begin
							txcount <= cmd_reg;
							cnt <= 8'b0;
							spi_state <= 4'h4;
							rdfifo <= false;
						end
				end
				4'h4:begin
					rdfifo <= true;
					cnt <= cnt + 1;
					spi_state <= 4'h5;
				end
				4'h5:begin
					rdfifo <= false;
					if(cnt >= txcount)
						begin
							spi_state <= 4'h0;
						end
					else
						begin
							spi_state <= 4'h6;
						end
				end
				4'h6:begin
					case(read_stat)
						0:begin
							if(txempty == false && negedge_spi_txcomp)
								begin
									read_stat <= 4'b1;
									rdfifo <= true;
									cnt <= cnt + 1;
								end
						end
						1:begin
							read_stat <= 4'h2;
							rdfifo <= false;
						end
						2:begin
							read_stat <= 4'b0;
							rdfifo <= false;
							spi_tx_data <= txdat;
						end
						default:begin
							read_stat <= 4'b0;
							rdfifo <= false;
						end
					endcase
				end
				default:begin
					spi_state <= 4'b0;
				end
			endcase
		end
end

wire [7:0]cmd_o;
wire [31:0]arg_o;
wire finsh_o;
wire [7:0]dat_o;
wire [7:0]status;
wire sd_en;
assign sd_en <= SDIO_CTRL_REG[0];

assign finsh = txfull;

ctrl sdio_ctrl(
		.rst(rst),
		.clk(clk),
		.txfull(txfull),
		.txen(txen),
		.dat_o(dat_o),
		.cmd_dat_i(cmd_o),
		.arg_i(arg_o),
		.finsh_i(finsh_o)
		);

sdio_sample sdio_sam(
		.rst(rst), 
		.sd_en(sd_en),
		.sd_clk(sd_clk), 
		.cmd_i(cmd_i), 
		.cmd_o(cmd_o), 
		.arg_o(arg_o),
		.finsh_o(finsh_o),
		.status(status)
		);


wire [5:0] fifo_level;

//wire rdfifo;

//assign rdfifo = spi_txcomp;

//assign txen = spi_rxdy;

//assign spi_data_i = txdat;

fifo_mxn #(8, 6) rxfifo(
		.rst(rst),
		.clk(clk),
		.ien(txen),
		.oen(rdfifo),
		.idat(dat_o),
		.odat(txdat),
		.full(txfull),
		.empty(txempty),
		.fifo_level(fifo_level)
		);
		

always @(posedge clk)
begin
	if(~rst)
		begin
			SDIO_FIFO_REG <= 8'b0;
		end
	else
		begin
			SDIO_FIFO_REG[5:0] <= fifo_level[5:0];
		end
end

/*
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
*/
endmodule
