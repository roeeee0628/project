module AFIFO #(parameter ADDRSIZE = 4,
			   parameter DATASIZE = 8)
(
	output [DATASIZE - 1 : 0]rdata,
	output rempty, wfull,
	input  wpush,rpop,wclk,rclk,
	input  [DATASIZE - 1 : 0]wdata,
	input  wrst_n,rrst_n
);
	wire [ADDRSIZE - 1 : 0]waddr,raddr;
	wire [ADDRSIZE : 0] wptr,rptr,wptr_rclk,rptr_wclk;
	FIFOmem 	#(DATASIZE ,ADDRSIZE) mem1 (
					.rdata(rdata),
					.wdata(wdata),
					.wen(wpush),
					.waddr(waddr),
					.wclk(wclk),
					.wfull(wfull),
					.raddr(raddr) 
				 	);



	sync_r2w    s1	(
						.rptr_wclk(rptr_wclk), 
						.rptr(rptr),      
						.wclk(wclk), 
						.wrst_n(wrst_n)
					); 
						 
	sync_w2r  	s2	(	
						.wptr_rclk(wptr_rclk), 
						.wptr(wptr), 
						.rclk(rclk), 
						.rrst_n(rrst_n)
					);  

	wprt_full 	#(ADDRSIZE) w1	(
						.waddr(waddr),
						.wptr(wptr),
						.wfull(wfull),
						.rptr_wclk(rptr_wclk),
						.wpush(wpush),
						.wclk(wclk),
						.wrst_n(wrst_n)
					);

	rptr_empty  #(ADDRSIZE) r1	(	
						.raddr(raddr),
						.rptr(rptr),
						.rempty(rempty),
						.wptr_rclk(wptr_rclk),
						.rpop(rpop),
						.rclk(rclk),
						.rrst_n(rrst_n)
					);

endmodule