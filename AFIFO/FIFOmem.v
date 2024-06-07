module FIFOmem #( parameter DATASIZE = 8,
				  parameter ADDRSIZE = 4)
(
	output [DATASIZE - 1 : 0] rdata,
	input [DATASIZE - 1 : 0] wdata,
	input wen,
	input [ADDRSIZE - 1 : 0] waddr,
	input wclk,wfull,
	input [ADDRSIZE - 1 : 0] raddr 
);
	`ifdef VENDORRAM    // instantiation of a vendor's dual-port RAM    
		vendor_ram mem (	.dout(rdata), 
							.din(wdata),                    
							.waddr(waddr), 
							.raddr(raddr), 
							.wclken(wclken), 
							.wclken_n(wfull), 
							.clk(wclk));  
	`else
		localparam DEPTH = 1 << (ADDRSIZE);
		reg [DATASIZE - 1 : 0] mem [0 : DEPTH - 1];
		assign rdata = mem[raddr];
		always @(posedge wclk )begin
			if(wen && !wfull)
				mem[waddr] <= wdata;
			else
				mem[waddr] <= mem[waddr];
		end
	`endif






endmodule