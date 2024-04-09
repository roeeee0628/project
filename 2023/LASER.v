module LASER (
input CLK,
input RST,
input [3:0] X,
input [3:0] Y,
output reg [3:0] C1X,
output reg [3:0] C1Y,
output reg [3:0] C2X,
output reg [3:0] C2Y,
output reg DONE);



//====================================================================
reg [3:0] X_reg [0:39];
reg [3:0] Y_reg [0:39];
reg [2:0] c_state ,n_state ;
reg [7:0] c_counter, n_counter;
reg [5:0] c_counter1, n_counter1;
reg [4:0] cir_count,n_cir_count,cir_count_2;
reg [4:0] max_cir_count;
reg [5:0] old_cir_count;
reg [7:0] max_address;
wire [8:0] dis1,dis2;
reg  label_reg [0:39];
parameter IDLE = 3'd0, TAKE = 3'd1, FIND_1 = 3'd2,COMPARE = 3'd3,CONVERGE = 3'd4,LABEL = 3'd5,FINISH = 3'd7;
integer i;



///////////////////state///////////////////////////////
always @(posedge CLK or posedge RST)begin
	if(RST)begin
		c_state <= IDLE;
	end
	else begin
		c_state <= n_state;
	end
end

always @(*)begin
	case(c_state)
		IDLE : 
			n_state = TAKE;
		TAKE :
			n_state = (c_counter == 6'd39) ? FIND_1 : TAKE;
		FIND_1 :
			n_state = (c_counter1 == 6'd38) ? COMPARE : FIND_1;
		COMPARE :
			n_state = (c_counter == 8'd255) ? CONVERGE : FIND_1;
		CONVERGE:
			n_state = (max_cir_count + cir_count_2 == old_cir_count) ? FINISH : LABEL;
		LABEL:
			n_state = (c_counter1 == 6'd38) ? FIND_1 : LABEL ;
		FINISH:
			n_state = IDLE;
		default:
			n_state = c_state;

	endcase
end
///////////////////X_reg Y_reg/////////////////////////
always @(posedge CLK or posedge RST)begin
	if(RST)begin
		for (i = 0 ; i <=39 ; i = i + 1)
			X_reg[i] <= 0;
	end
	else begin
		case(c_state)
			IDLE :
				X_reg[0] <= X;
			TAKE :
				X_reg[c_counter] <= X;
			default:
				for (i = 0 ; i <=39 ; i = i + 1)
					X_reg[i] <= X_reg[i];
		endcase
	end
end


always @(posedge CLK or posedge RST)begin
	if(RST)begin
		for (i = 0 ; i <=39 ; i = i + 1)
			Y_reg[i] <= 0;
	end
	else begin
		case(c_state)
			IDLE :
				Y_reg[0] <= Y;
			TAKE :
				Y_reg[c_counter] <= Y;
			default:
				for (i = 0 ; i <=39 ; i = i + 1)
					Y_reg[i] <= Y_reg[i];
		endcase
	end
end



/////////////////counter//////////////////////////
always @(posedge CLK or posedge RST)begin
	if(RST)begin
		c_counter <= 1;
	end
	else begin
		c_counter <= n_counter;
	end
end

always @(*)begin
	case(c_state)
		TAKE : 
			n_counter = (c_counter == 6'd39) ? 0 : c_counter + 1;
		COMPARE :
			n_counter = (c_counter == 8'd255) ? 0 : c_counter + 1;
		CONVERGE :
			n_counter = {C1Y,C1X};
		LABEL :
			n_counter = (c_counter1 == 6'd38) ? 0 : c_counter; 
		FINISH :
			n_counter = 0;
		default:
			n_counter = c_counter;
	endcase
end

always @(posedge CLK or posedge RST)begin
	if(RST)begin
		c_counter1 <= 0;
	end
	else begin
		c_counter1 <= n_counter1;
	end
end

always @(*)begin
	case(c_state)
		FIND_1 :
			n_counter1 = (c_counter1 == 6'd38) ? 0 : c_counter1 + 2;
		LABEL :
			n_counter1 = (c_counter1 == 6'd38) ? 0 : c_counter1 + 2;
		FINISH :
			n_counter1 = 0;
		default:
			n_counter1 = c_counter1;
	endcase
end


//////////////////cir_count///////////////////////////

assign dis1 = (X_reg[c_counter1] - c_counter[3:0]) * (X_reg[c_counter1] - c_counter[3:0])
+ (Y_reg[c_counter1] - c_counter[7:4]) * (Y_reg[c_counter1] - c_counter[7:4]) | {8{label_reg[c_counter1]}};
assign dis2 = (X_reg[c_counter1 + 1] - c_counter[3:0]) * (X_reg[c_counter1 + 1] - c_counter[3:0])
+ (Y_reg[c_counter1 + 1] - c_counter[7:4]) * (Y_reg[c_counter1 + 1] - c_counter[7:4]) | {8{label_reg[c_counter1 + 1]}};

always @(posedge CLK or posedge RST)begin
	if(RST)begin
		cir_count <= 0;
	end
	else begin
		cir_count <= n_cir_count;
	end
end

always @(posedge CLK or posedge RST)begin
	if(RST)begin
		cir_count_2 <= 0;
	end
	else begin
		case(c_state)
			CONVERGE:
				cir_count_2 <= max_cir_count;
			FINISH :
				cir_count_2 <= 0;
			default :
				cir_count_2 <= cir_count_2;
		endcase
	end
end

always @(*)begin
	case(c_state)
		FIND_1 :begin
			if((dis1 <= 5'd16) && (dis2 <= 5'd16))
				n_cir_count = cir_count + 2;
			else if((dis1 <= 5'd16) || (dis2 <= 5'd16))
				n_cir_count = cir_count + 1;
			else
				n_cir_count = cir_count;
		end
		COMPARE :
			n_cir_count = 0;
		default: 
			n_cir_count = cir_count;
	endcase
end


always @(posedge CLK or posedge RST)begin
	if(RST)begin
		max_cir_count <= 0;
	end
	else begin
		case(c_state)
			COMPARE:begin
				if(cir_count >= max_cir_count)
					max_cir_count <= cir_count ;
				else
					max_cir_count <= max_cir_count;
			end
			CONVERGE:begin
				max_cir_count <= 0;
			end
			default :
				max_cir_count <= max_cir_count;
		endcase
	end
end

always @(posedge CLK or posedge RST)begin
	if(RST)begin
		old_cir_count <= 0;
	end
	else begin
		case(c_state)
			CONVERGE:
				old_cir_count <= max_cir_count + cir_count_2;
			FINISH:
				old_cir_count <= 0;
			default :
				old_cir_count <= old_cir_count;
		endcase
	end
end

///////////////max_address/////////////////////////

always @(posedge CLK or posedge RST)begin
	if(RST)begin
		max_address <= 0;
	end
	else begin
		case(c_state)
			COMPARE:begin
				if(cir_count  >= max_cir_count)
					max_address <= c_counter;
			end
			default
				max_address <= max_address;
		endcase
	end
end

//////////////label_reg/////////////////////
always @(posedge CLK or posedge RST)begin
	if(RST)begin
		for(i = 0 ; i <=39 ; i = i + 1)
			label_reg[i] <= 0;
	end
	else begin
		case(c_state)
			CONVERGE:
				for(i = 0 ; i <=39 ; i = i + 1)
					label_reg[i] <= 0;			
			LABEL: begin
				if(dis1 <= 5'd16)
					label_reg[c_counter1] <= 1;
				else
					label_reg[c_counter1] <=label_reg[c_counter1];
				if(dis2 <= 5'd16)
					label_reg[c_counter1 + 1] <= 1;
				else
					label_reg[c_counter1 + 1] <=label_reg[c_counter1 + 1];				
			end
			default:
				for(i = 0 ; i <=39 ; i = i + 1)
						label_reg[i] <= label_reg[i];			
		endcase
	end
end



///////////////C1X C1Y////////////////////////
always @(posedge CLK or posedge RST)begin
	if(RST)begin
		C1X <= 0;
		C1Y <= 0;
	end
	else begin
		case(c_state)
			COMPARE :begin
				if(cir_count >= max_cir_count)begin
					C1X <= c_counter[3:0];
					C1Y <= c_counter[7:4];
				end
				else begin
					C1X <= C1X; 
					C1Y <= C1Y;
				end
			end
			default:begin
				C1X <= C1X; 
				C1Y <= C1Y;
			end
		endcase
	end
end

///////////////C2X C2Y////////////////////////
always @(posedge CLK or posedge RST)begin
	if(RST)begin
		C2X <= 0;
		C2Y <= 0;
	end
	else begin
		case(c_state)
			LABEL :begin
				C2X <= C1X; 
				C2Y <= C1Y;				
			end
			default:begin
				C2X <= C2X; 
				C2Y <= C2Y;
			end
		endcase
	end
end




//////////////////DONE//////////////////////////////
always @(posedge CLK or posedge RST)begin
	if(RST)begin 
		DONE <= 0;
	end
	else begin
		if(c_state == CONVERGE)begin
			if(max_cir_count + cir_count_2 == old_cir_count)
				DONE <= 1;
			else begin
				DONE <= 0;
			end
		end
		else begin
			DONE <=0;
		end
	end
end
endmodule


