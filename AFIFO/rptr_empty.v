module rptr_empty #(parameter ADDRSIZE = 4)
(
	output [ADDRSIZE - 1 : 0] raddr,
	output reg [ADDRSIZE : 0] rptr,
	output reg rempty,
	input [ADDRSIZE : 0] wptr_rclk,
	input rpop,rclk,rrst_n
);
	reg  [ADDRSIZE : 0]rbin;
	wire [ADDRSIZE : 0]n_rbin,n_rptr;

	always @(posedge rclk or negedge rrst_n)begin
		if(~rrst_n)begin
			rptr <= 0;
			rbin <= 0;
		end
		else begin
			rptr <= n_rptr;
			rbin <= n_rbin;
		end
	end 

	assign n_rbin = rbin + (~rempty & rpop);
	assign n_rptr = {0,n_rbin >> 1} ^ n_rbin;
	assign raddr = rbin[ADDRSIZE - 1:0];
	always @(posedge rclk or negedge rrst_n)begin
		if(~rrst_n)begin
			rempty <= 0;
		end
		else begin
			if(n_rptr == wptr_rclk)
				rempty <= 1;
			else begin
				rempty <= 0;
			end
		end
	end




endmodule