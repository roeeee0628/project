module sync_w2r #(parameter ADDRSIZE = 4)
(
	output reg [ADDRSIZE : 0]wptr_rclk,
	input rclk, rrst_n,
	input [ADDRSIZE : 0] wptr 
);
	reg [ADDRSIZE : 0] wptr_rclk1 ;

	always @(posedge rclk or negedge rrst_n)begin
		if(~rrst_n)
			{wptr_rclk , wptr_rclk1} <= {0 , 0};
		else begin
			{wptr_rclk , wptr_rclk1} <= {wptr_rclk1 , wptr} ;
		end
	end



endmodule