module sync_r2w #(parameter ADDRSIZE = 4)
(
	output reg [ADDRSIZE : 0] rptr_wclk,
	input [ADDRSIZE : 0] rptr,
	input wclk , wrst_n
);
	reg [ADDRSIZE : 0] rptr_wclk1;
	always @(posedge wclk or negedge wrst_n)begin
		if(~wrst_n)
			{rptr_wclk , rptr_wclk1} <= {0 , 0};
		else begin
			{rptr_wclk , rptr_wclk1} <= {rptr_wclk1 , rptr};
		end

	end


endmodule