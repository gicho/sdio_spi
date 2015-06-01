`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:15:02 03/10/2014 
// Design Name: 
// Module Name:    ctrl 
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
module ctrl(
	input rst,
	input clk,
	input txfull,
	output txen,
	output reg [7:0]dat_o,
	input [7:0]cmd_dat_i,
	input [31:0]arg_i,
	input finsh_i
    );

	parameter true = 1'b0, false = 1'b1;
	reg txe = false;
	assign txen = txe;
	
	reg [7:0] cmd_dat;
	parameter BUFF_LEN = 8;
	reg [7:0]dat_buff[BUFF_LEN-1:0];
	integer buff_len;
	integer ptr;
	
	reg ienbuf = 1'b0;
	wire negedge_ien = ienbuf & ~finsh_i;
	
	reg [2:0]ctrstate = IDLE;
	parameter IDLE = 3'd1, PARSE_CMD = 3'd2, TXDAT = 3'd3, TXWAIT = 3'd4, TXFINSH = 3'd5;
	
	always @(posedge clk) begin
		cmd_dat <= cmd_dat_i;
	end
	
	always @(posedge clk or negedge rst) begin
		if (rst == 1'b0) begin
			ienbuf <= 1'b0;
		end
		else begin
			ienbuf <= finsh_i;
		end
	
	end
	
	
	always @(posedge clk or negedge rst) begin
		if(rst == 1'b0) begin
			txe <= 1'b0;
			ctrstate <= IDLE;
			buff_len <= 0;
			ptr <= 0;
		end
		else begin
			case(ctrstate)
				IDLE: begin
					txe <= 1'b0;
					ptr <= 0;
					if(negedge_ien && (txfull == false)) begin
						ctrstate <= PARSE_CMD;
					end
				end
				PARSE_CMD: begin
					//dat_o <= cmd_dat_i;
					//if (cmd_dat == 25 || cmd_dat == 18) begin
						dat_buff[0] <= 8'hf0;
						dat_buff[1] <= cmd_dat;
						dat_buff[2] <= arg_i[31:24];
						dat_buff[3] <= arg_i[23:16];
						dat_buff[4] <= arg_i[15:8];
						dat_buff[5] <= arg_i[7:0];
						/* dat_buff[1] <= 8'h0d;
						dat_buff[2] <= 8'h1e;
						dat_buff[3] <= 8'hda;
						dat_buff[4] <= 8'h1f;
						dat_buff[5] <= 8'h00;*/
						dat_buff[6] <= 8'hff;
						buff_len <= 7;
					/*end
					else begin
						dat_buff[0] <= cmd_dat;
						buff_len <= 1;
					end*/
					//txe <= 1'b1;
					ctrstate <= TXDAT;
				end
				TXDAT: begin
					if (ptr < buff_len) begin
						txe <= 1'b1;
						dat_o <= dat_buff[ptr];
						ctrstate <= TXWAIT;
					end
					else begin
						ctrstate <= TXFINSH;
					end
					ptr <= ptr + 1;
				end
				TXWAIT: begin
					txe <= 1'b0;
					ctrstate <= TXDAT;
				end
				TXFINSH: begin
					ctrstate <= IDLE;
				end
			endcase
		end
	end

endmodule
