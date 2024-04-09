module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);

input               clk;
input               reset;
input               gray_ready;
input      [7:0]    gray_data;

output reg [13:0]   gray_addr;
output reg          gray_req;
output reg [13:0]   lbp_addr;
output reg          lbp_valid;
output reg [7:0]    lbp_data;
output reg          finish;

reg [13:0] c_gray_addr_pos,n_gray_addr_pos,n_gray_addr_tmp;
reg [7:0] c_mid_gray_data,n_mid_gray_data;
reg [7:0] c_gray_data_tmp,n_gray_data_tmp;
reg [1:0] c_state,n_state;
reg [3:0] c_count,n_count;
reg [8:0] c_lbp_value , n_lbp_value;
integer i;
parameter IDLE = 0 ,START = 2'd1,TAKE_MID =2'd2,TAKE_AROUND = 2'd3;



//counter
always @(posedge clk or posedge reset) begin
	if (reset) begin
		c_count <= 0;
	end
	else  begin
		c_count <= n_count;
	end
end

//state
always @(posedge clk or posedge reset) begin
	if (reset) begin
		c_state <= IDLE;	
	end
	else  begin
		c_state <= n_state;	
	end
end


//mid_gray_data
always @(*)begin 
	case(c_state)
		TAKE_MID :
			n_mid_gray_data = gray_data;
		default :
			n_mid_gray_data = c_mid_gray_data;
	endcase

end

//c_mid_gray_data
always @(posedge clk or posedge reset) begin
	if (reset) begin
		c_mid_gray_data <= 0;
	end
	else  begin
		c_mid_gray_data <= n_mid_gray_data;
	end
end

//c_gray_addr_pos
always @(posedge clk or posedge reset) begin
	if (reset) begin
		c_gray_addr_pos <= 14'd129;
	end
	else  begin
		c_gray_addr_pos <= n_gray_addr_pos;
	end
end


// c_lbp_value
always @(posedge clk or posedge reset) begin
	if (reset) begin
		c_lbp_value <= 0;
	end
	else  begin
		c_lbp_value <= n_lbp_value ;
		
	end
end

//state
always @(*)begin 
	case(c_state)
		IDLE : 
			n_state = (gray_ready) ? START : IDLE;
		START : 
			n_state = TAKE_MID;
		TAKE_MID :
			n_state = TAKE_AROUND;
		TAKE_AROUND : begin
			n_state = (c_count < 4'd9) ? TAKE_AROUND : START;		
		end 
		default : 
			n_state = c_state;
	endcase

end


//count
always @(*)begin 
	if(c_state == TAKE_AROUND)
		n_count = (c_count < 4'd9) ? c_count + 1 : 0;
	else 
		n_count = c_count;
end



// controll signal gray_req
always @(posedge clk or posedge reset) begin
	if (reset) 
		gray_req <= 0; 
	else  begin
		case(c_state)
			START :
				gray_req <= 1 ;
			TAKE_MID :
				gray_req <= 1 ;
			
			TAKE_AROUND : begin
				if (c_count < 4'd9 )
					gray_req <= 1 ;
				else 
					gray_req <= 0;		
			end 
			default : 
				gray_req <= 0;
		endcase
	end
end

// controll signal lbp_valid
always @(posedge clk or posedge reset)begin 
	if(reset)
		lbp_valid <= 0; 
	else if(c_state == TAKE_AROUND) begin 
		lbp_valid <= (c_count == 4'd8) ? 1'd1 : 0 ;
	end
	else 
		lbp_valid <= 0;

end

// controll signal finish
always @(posedge clk or posedge	reset)begin  
	if(reset)
		finish <= 0;
	else if(c_state == TAKE_AROUND) begin 
		if(c_gray_addr_pos > 14'd16254)
			finish <= 1; 
		else begin
			finish <= 0;
		end
	end
	else begin
		finish <= 0;		
	end
end

//n_gray_addr_pos
always @(*)begin 
	if(c_state == TAKE_AROUND)begin
		if(c_gray_addr_pos[6:0]==7'b1111110)
			n_gray_addr_pos = (c_count < 4'd9) ? c_gray_addr_pos : (c_gray_addr_pos + 2'd3);
		else 
			n_gray_addr_pos = (c_count < 4'd9) ? c_gray_addr_pos : (c_gray_addr_pos + 1'd1);
	end
	else 
	 	n_gray_addr_pos = c_gray_addr_pos;

end




//gray-data_tmp
always @(posedge clk or posedge reset)begin
	if (reset)
		c_gray_data_tmp <= 0;
	else if(c_state == TAKE_MID)
		c_gray_data_tmp <= (gray_req) ? gray_data : n_gray_data_tmp;
	else if(c_state == TAKE_AROUND)
		c_gray_data_tmp <= (gray_req) ? gray_data : n_gray_data_tmp;
	else 
		c_gray_data_tmp <= n_gray_data_tmp;	
end

always @(*)begin
	n_gray_data_tmp = c_gray_data_tmp;
end


//gray_addr_tmp
always @(*)begin 
	case(c_state)
		TAKE_MID :
			n_gray_addr_tmp = c_gray_addr_pos - 8'd129;
		TAKE_AROUND : begin
			case (c_count) 
				4'd0: begin
					n_gray_addr_tmp = c_gray_addr_pos - 8'd128;
				end
				4'd1: begin
					n_gray_addr_tmp = c_gray_addr_pos - 8'd127;
				end
				4'd2: begin
					n_gray_addr_tmp = c_gray_addr_pos - 8'd1;
				end
				4'd3: begin
					n_gray_addr_tmp = c_gray_addr_pos + 8'd1;
				end
				4'd4: begin
					n_gray_addr_tmp = c_gray_addr_pos + 8'd127;
				end
				4'd5: begin
					n_gray_addr_tmp = c_gray_addr_pos + 8'd128;
				end
				4'd6: begin
					n_gray_addr_tmp = c_gray_addr_pos + 8'd129;
				end
			default :
				n_gray_addr_tmp = c_gray_addr_pos;
			endcase
		end
		default :
			n_gray_addr_tmp = c_gray_addr_pos;
	endcase

end




//lbp_value
always @(*)begin 
	case(c_state)
		TAKE_AROUND: begin
			case (c_count) 
				4'd1: begin
					if (c_gray_data_tmp >= (c_mid_gray_data) )begin
							n_lbp_value = c_lbp_value + 9'd1;
					end
					else 
						n_lbp_value = c_lbp_value;
				end
				4'd2: begin
					if (c_gray_data_tmp >= (c_mid_gray_data) )begin
							n_lbp_value = c_lbp_value + 9'd2;
					end
					else 
						n_lbp_value = c_lbp_value;
				end
				4'd3: begin
					if (c_gray_data_tmp >= (c_mid_gray_data) )begin
							n_lbp_value = c_lbp_value + 9'd4;
					end
					else 
						n_lbp_value = c_lbp_value;
				end
				4'd4: begin
					if (c_gray_data_tmp >= (c_mid_gray_data) )begin
							n_lbp_value = c_lbp_value + 9'd8;
					end
					else 
						n_lbp_value = c_lbp_value;
				end
				4'd5: begin
					if (c_gray_data_tmp >= (c_mid_gray_data) )begin
							n_lbp_value = c_lbp_value + 9'd16;
					end
					else 
						n_lbp_value = c_lbp_value;
				end
				4'd6: begin
					if (c_gray_data_tmp >= (c_mid_gray_data) )begin
							n_lbp_value = c_lbp_value + 9'd32;
					end
					else 
						n_lbp_value = c_lbp_value;
				end
				4'd7: begin
					if (c_gray_data_tmp >= (c_mid_gray_data) )begin
							n_lbp_value = c_lbp_value + 9'd64;
					end
					else 
						n_lbp_value = c_lbp_value;
				end
				4'd8: begin
					if (c_gray_data_tmp >= (c_mid_gray_data) )begin
							n_lbp_value = c_lbp_value + 9'd128;
					end
					else 
						n_lbp_value = c_lbp_value;
				end
				default : begin 
					n_lbp_value = c_lbp_value;
				end
			endcase
		end
		default : 
			n_lbp_value = 0 ;
	endcase

end


//gray_addr
always @(posedge clk or posedge reset) begin
	if (reset) begin
		gray_addr <= 14'd129;

	end
	else 
		gray_addr <= n_gray_addr_tmp;

end

//lbp_data
always @(posedge clk or posedge reset) begin
	if (reset) begin
		lbp_data <= 0;
		//finish <= 0;

	end
	else if (c_state == TAKE_AROUND) begin
		lbp_data <= n_lbp_value;
	end
	else begin 
		lbp_data <= 0;

	end

end

//lbp_addr
always @(posedge clk or posedge reset) begin
	if (reset) begin
		lbp_addr <= 14'd129;
		//finish <= 0;

	end
	else if (c_state == TAKE_AROUND) begin
		lbp_addr <= c_gray_addr_pos;
	end
	else begin 
		lbp_addr <= c_gray_addr_pos;
	end

end
endmodule
