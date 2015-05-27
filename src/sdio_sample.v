`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:15:42 03/04/2014 
// Design Name: 
// Module Name:    sdio_sample 
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
module sdio_sample(
		rst, 
		sd_clk, 
		cmd_i, 
		cmd_o, 
		arg_o,
		finsh_o,
		status
		);
input rst;
input sd_clk;
input cmd_i;
output reg [7:0]cmd_o;
output reg [32:0]arg_o;
output reg finsh_o;
output reg [7:0] status;
//-------------Internal Constant-------------
parameter INIT_DELAY = 4;
parameter BITS_TO_SEND = 48;
parameter CMD_SIZE = 48;
parameter RESP_SIZE = 136;
parameter MAXLAT = 64;
//---------------Internal variable-----------
reg cmd_dat_reg;
reg [CMD_SIZE-1:0] cmd_buff;
reg [RESP_SIZE-1:0] resp_buff;
//-Internal Counterns
integer resp_cnt;
integer counter;
integer resp_len;
reg with_response;
//-State Machine
reg [6:0]capstate;
reg [6:0]next_st;
parameter IDLE = 7'h01, FOUND_START = 7'h02, FOUND_CMD = 7'h04, WAIT_RESP = 7'h08, 
		FOUND_RESP = 7'h10, FINSH_CAP = 7'h20;

`define cmd_idx  (CMD_SIZE-1-counter) 
`define resp_idx  (RESP_SIZE-1-counter) 

always @(posedge sd_clk)
	cmd_dat_reg <= cmd_i;

always @(capstate or cmd_dat_reg or counter or with_response or resp_len)
begin
	case(capstate)
		IDLE: begin
			if (!cmd_dat_reg)
				next_st <= FOUND_START;
			else
				next_st <= IDLE;
		end
		FOUND_START: begin
			if (cmd_dat_reg)
				next_st <= FOUND_CMD;
			else
				next_st <= IDLE;
		end
		FOUND_CMD: begin
			if (counter >= CMD_SIZE)
				if (with_response)
					next_st <= WAIT_RESP;
				else
					next_st <= FINSH_CAP;
			else
				next_st <= FOUND_CMD;
		end
		WAIT_RESP: begin
			if (resp_cnt < MAXLAT) begin
				if (!cmd_dat_reg)
					next_st <= FOUND_RESP;
				else
					next_st <= WAIT_RESP;
			end
			else begin
				next_st <= FINSH_CAP;
			end
		end
		FOUND_RESP: begin
			if (counter >= resp_len)
				next_st <= FINSH_CAP;
			else
				next_st <= FOUND_RESP;
		end
		FINSH_CAP: begin
			next_st <= IDLE;
		end
		default: begin
			next_st <= IDLE;
		end
	endcase
end

always @(posedge sd_clk or negedge rst)
begin
	if (!rst)
		capstate <= IDLE;
	else
		capstate <= next_st;
end

always @(posedge sd_clk or negedge rst)
begin
	if (!rst) begin
		cmd_o <= 0;
		arg_o <= 0;
		finsh_o <= 0;
		resp_cnt <= 0;
		counter <= 0;
		with_response <= 0;
		status <= 0;
	end
	else begin
		status <= capstate;
		case (capstate)
			IDLE: begin
				finsh_o <= 0;
				resp_cnt <= 0;
				counter <= 2;
				cmd_buff[CMD_SIZE-1] <= cmd_dat_reg;
			end
			FOUND_START: begin
				//counter <= counter + 1;
				cmd_buff[CMD_SIZE-2] <= cmd_dat_reg;
			end
			FOUND_CMD: begin
				//counter <= counter + 1;
				if (counter < CMD_SIZE)
					cmd_buff[`cmd_idx] <= cmd_dat_reg;
				else begin
					if (cmd_buff[45:40] != 6'd0) begin
						with_response <= 1'b1;
						counter <= 0;
					end
					else
						with_response <= 1'b0;
				end
				counter <= counter + 1;
			end
			WAIT_RESP: begin
				case(cmd_buff[45:40])
					6'd2: resp_len <= 136; //CMD2
					6'd9: resp_len <= 136; //CMD9
					default: resp_len <= 48;
				endcase
				counter <= 1;
				resp_buff[RESP_SIZE-1] <= cmd_dat_reg;
				resp_cnt <= resp_cnt + 1;
			end
			FOUND_RESP: begin
				//counter <= counter + 1;
				if (counter < resp_len)
					resp_buff[`resp_idx] <= cmd_dat_reg;
				counter <= counter + 1;
			end
			FINSH_CAP: begin
				//if (cmd_buff[45:40] == resp_buff[133:128]) begin
					cmd_o <= cmd_buff[45:40];
					arg_o <= cmd_buff[39:8];
					finsh_o <= 1;
					counter <= 0;
					//$display("		%b", cmd_buff);
				//end
			end
		endcase
		
		//$monitor("       %b", capstate);
		//$monitor("       %b", cmd_buff);
	end
end

endmodule
