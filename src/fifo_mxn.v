
module fifo_mxn(rst, clk, ien, oen, 
	idat, odat, full, empty);
	
	parameter dw = 8;
	parameter aw = 4;
	parameter max_size = 1 << aw;
	parameter true = 1'b0, false = 1'b1;
	
	input rst;
	input clk;
	input ien;
	input oen;
	input [dw-1:0] idat;
	output [dw-1:0] odat;
	output full;
	output empty;
	
	reg [dw-1:0] mem [0:max_size-1];
	reg [aw-1:0] wraddr = {aw{1'b0}};
	reg [aw-1:0] rdaddr = {aw{1'b0}};
	wire [aw-1:0] datnum = wraddr - rdaddr;
	assign empty = datnum == {aw{1'b0}} ? true : false;
	assign full  = datnum == {aw{1'b1}} ? true : false;
	reg [dw-1:0] odatq;
	assign odat = odatq;
	reg ienbuf = 1'b0, oenbuf = 1'b0;
	wire negedge_ien = ienbuf & ~ien;
	wire negedge_oen = oenbuf & ~oen;
	always @ (posedge clk or negedge rst) begin 
		if(rst == 1'b0) begin //reset
			ienbuf <= 1'b0;
			oenbuf <= 1'b0;
			end
		else begin //buffer
			ienbuf <= ien;
			oenbuf <= oen;
			end
		end
	always @ (posedge clk or negedge rst) begin
		if(rst == 1'b0) begin //reset
			wraddr <= {aw{1'b0}};
			rdaddr <= {aw{1'b0}};
			odatq <= {dw{1'b0}};
			end
		else begin
			if(negedge_ien && full == false) begin //push
				mem[wraddr] <= idat;
				wraddr <= wraddr + 1'b1;
				end
			if(negedge_oen && empty == false) begin //pop
				odatq <= mem[rdaddr];
				rdaddr <= rdaddr + 1'b1;
				end
			end
		end
endmodule
