`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:26:35 05/15/2015 
// Design Name: 
// Module Name:    spi_slave 
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

module SPI_slave(rst, clk, SCK, MOSI, MISO, SSEL, spi_data_i, spi_txcomp, spi_data_o, spi_rxdy);
input rst;
input clk;

input SCK, SSEL, MOSI;
output MISO;
input [7:0] spi_data_i;
output spi_txcomp;
output [7:0] spi_data_o;
output spi_rxdy;


// sync SCK to the FPGA clock using a 3-bits shift register
reg [2:0] SCKr;
always @(posedge clk)
begin
	if (~rst)
		begin
			SCKr <= 3'b0;
		end
	else
		begin
			SCKr <= {SCKr[1:0], SCK};
		end
end

wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

// same thing for SSEL
reg [2:0] SSELr;
always @(posedge clk)
begin
	if(~rst)
		begin
			SSELr <= 3'b111;
		end
	else
		begin
			SSELr <= {SSELr[1:0], SSEL};
		end
end

wire SSEL_active = ~SSELr[1];  // SSEL is active low
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

// and for MOSI
reg [1:0] MOSIr;
always @(posedge clk)
begin
	if(~rst)
		begin
			MOSIr <= 2'b0;
		end
	else
		begin
			MOSIr <= {MOSIr[0], MOSI};
		end
end

wire MOSI_data = MOSIr[1];

// we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
reg [2:0] bitcnt;

reg byte_received;  // high when a byte has been received
reg [7:0] byte_data_received;

assign spi_data_o = byte_data_received;
assign spi_rxdy = byte_received;

always @(posedge clk)
begin
	if(~rst)
		begin
			bitcnt <= 3'b000;
			byte_data_received <= 0;
		end
	else
		begin
			if(~SSEL_active)
				begin
					bitcnt <= 3'b000;
					byte_data_received <= 0;
				end
			else
				begin
					if(SCK_risingedge)
						begin
							bitcnt <= bitcnt + 3'b001;

							// implement a shift-left register (since we receive the data MSB first)
							byte_data_received <= {byte_data_received[6:0], MOSI_data};
						end
					else
						begin
							byte_data_received <= byte_data_received;
						end
				end
		end
end

always @(posedge clk)
begin
	if(~rst)
		begin
			byte_received <= 1'b0;
		end
	else
		begin
			byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);
		end
end

// we use the LSB of the data received to control an LED
//reg LED;
//always @(posedge clk) if(byte_received) LED <= byte_data_received[0];

reg byte_sent;
reg [7:0] byte_data_sent;

//assign spi_data_i = byte_data_sent;
assign spi_txcomp = byte_sent;

always @(posedge clk)
begin
	if(~rst)
		begin
			byte_sent <= 1'b0;
		end
	else
		begin
			byte_sent <= SSEL_active && SCK_fallingedge && (bitcnt==3'b111);
		end
end

reg [7:0] cnt;
always @(posedge clk)
begin
	if(~rst)
		begin
			cnt <= 8'h0;
		end
	else
		begin
			//if(SSEL_startmessage) cnt<=cnt+8'h1;  // count the messages
			if(SCK_risingedge) cnt<=cnt+8'h1;  // count the messages
			else cnt <= cnt;
		end
end

always @(posedge clk)
begin
	if(~rst)
		begin
			byte_data_sent <= 8'h0;
		end
	else
		begin
			if(SSEL_active)
				begin
					if(bitcnt==3'b000/*SSEL_startmessage*/)
						byte_data_sent <= spi_data_i;  // first byte sent in a message is the message count
						//byte_data_sent <= byte_data_received;
					else
						if(SCK_fallingedge)
							begin
								/*if(bitcnt==3'b000)
									//byte_data_sent <= 8'h00;  // after that, we send 0s
									byte_data_sent <= byte_data_sent;
								else*/
									byte_data_sent <= {byte_data_sent[6:0], 1'b0};
							end
						else
							begin
								byte_data_sent <= byte_data_sent;
							end
				end
			else
				begin
					byte_data_sent <= byte_data_sent;
				end
		end
end

assign MISO = byte_data_sent[7];  // send MSB first
// we assume that there is only one slave on the SPI bus
// so we don't bother with a tri-state buffer for MISO
// otherwise we would need to tri-state MISO when SSEL is inactive

endmodule