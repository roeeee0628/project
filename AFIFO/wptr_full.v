module wprt_full #(parameter ADDRSIZE = 4)
(
	output [ADDRSIZE - 1 : 0] waddr,
	output reg [ADDRSIZE : 0] wptr,
	output reg wfull,
	input [ADDRSIZE : 0] rptr_wclk,
	input wpush,wclk,wrst_n
);
	reg [ADDRSIZE : 0] wbin;
	wire [ADDRSIZE : 0] n_wbin,n_wptr;

	always @(posedge wclk or negedge wrst_n) begin
		if (~wrst_n) begin
			wbin <= 0;
			wptr <= 0;
		end
		else begin
			wbin <= n_wbin;
			wptr <= n_wptr;
		end
	end

	assign n_wbin = wbin + (wpush & ~wfull);
	assign n_wptr = {0,(n_wbin >> 1)} ^ n_wbin ;
	assign waddr = wbin[ADDRSIZE - 1 :0];


	always @(posedge wclk or negedge wrst_n)begin
		if(~wrst_n)
			wfull <= 0 ; 
		else begin
			wfull <= {~ rptr_wclk[ADDRSIZE : ADDRSIZE -1] , n_wptr[ADDRSIZE - 2 : 0]} == n_wptr;
		end
	end




endmodule