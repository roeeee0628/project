//synopsys translate_off
`include "DW_sqrt.v"
//synopsys translate_on

module geofence ( clk,reset,X,Y,R,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
input [10:0] R;
output reg valid;
output reg is_inside;


reg [3:0]c_state,n_state;
reg [9:0] X_reg [0:5];
reg [9:0] Y_reg [0:5];
reg [10:0] R_reg [0:5];
reg signed [10:0] X_vector[0:4];
reg signed [10:0] Y_vector[0:4];
reg [3:0] c_counter,n_counter ;
reg [2:0] c_counter1,n_counter1;
reg signed [22:0] product [0:1];
reg [12:0]product1,product2; 
reg [11:0] a ;
reg [22:0] n_a;
reg [23:0] area_tri,n_area_tri;
reg signed [23:0] area_hex,n_area_hex;
wire [11:0] root;
reg signed [11:0] absolute_value;
reg [11:0] absoulte_value1;
parameter IDLE = 4'd0,TAKE = 4'd1 ,FINISH = 4'd13,VECTOR = 4'd2,OUTER_PRODUCT = 4'd3,
COMPARE = 4'd4,SIDELENGTH = 4'd5 ,SIDELENGTH1 = 4'd6, GEO1 = 4'd7 , GEO2 = 4'd8, AREA_SIX = 4'd9
,OUT_IN = 4'd10,GEO1_SIGN = 4'd11,GEO2_SIGN = 4'd12;
integer i;
reg [12:0] s; //可修

DW_sqrt #(23,0) D1 (.a(n_a ),.root(root));
///////state//////////////
always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	c_state <= IDLE;
	 end
	 else begin
	 	c_state <= n_state;
	 end
end 

always @(*)begin
	case(c_state)
		IDLE:
			n_state = TAKE;
		TAKE:
			n_state = (c_counter == 4'd5) ? VECTOR : TAKE;
		VECTOR:
			n_state = (c_counter == 4'd4) ? OUTER_PRODUCT: VECTOR;
		OUTER_PRODUCT:
			n_state =  COMPARE ;
		COMPARE :
			n_state = (c_counter == 4'd3) ? SIDELENGTH : OUTER_PRODUCT;
		SIDELENGTH :
			n_state = SIDELENGTH1;
		SIDELENGTH1 :
			n_state = GEO1_SIGN;
		GEO1_SIGN :
			n_state = GEO1;
		GEO1 :
			n_state = GEO2_SIGN;
		GEO2_SIGN :
			n_state = GEO2;
		GEO2:
			n_state = (c_counter == 4'd5) ? AREA_SIX : SIDELENGTH; 
		AREA_SIX:
			n_state = (c_counter == 4'd5) ? OUT_IN : AREA_SIX; 
		OUT_IN :
			n_state = FINISH;
		FINISH :
			n_state = IDLE;
		default:
			n_state = c_state; 
	endcase
end
///////signal/////////////
always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	valid <= 0;
	 end
	 else begin
	 	case(c_state)
	 		OUT_IN :
	 			valid <= 1;
	 		default:
	 			valid <= 0;
	 	endcase
	 end
end 

always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	is_inside <= 0;
	 end
	 else begin
	 	case(c_state)
	 		OUT_IN :
	 			if (area_tri >= area_hex)
	 				is_inside <= 0;
	 			else 
	 				is_inside <= 1;
	 		default:
	 			is_inside <= 0;
	 	endcase
	 end
end


///////X_reg//////////////
always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	for (i = 0;i < 6; i = i + 1)
	 		X_reg[i] <= 0;
	 end
	 else begin
	 	case(c_state)
	 		IDLE:
	 			X_reg[0] <= X;
	 		TAKE:
	 			X_reg[c_counter] <= X;
	 		COMPARE:begin
	 			if(product[0] > product[1])begin
					X_reg[c_counter + 1] <=	X_reg[c_counter1+ 1 ];		
					X_reg[c_counter1+ 1]<= X_reg[c_counter + 1];
				end
				else begin
					X_reg[c_counter] <=	X_reg[c_counter];		
					X_reg[c_counter1]<= X_reg[c_counter1];
				end
	 		end
	 		default:
	 			for (i = 0;i < 6; i = i + 1)
	 				X_reg[i] <= X_reg[i];	
	 	endcase  			
	 end
end 


///////Y_reg//////////////
always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	for (i = 0;i < 6; i = i + 1)
	 		Y_reg[i] <= 0;
	 end
	 else begin
	 	case(c_state)
	 		IDLE:
	 			Y_reg[0] <= Y;
	 		TAKE:
	 			Y_reg[c_counter] <= Y;
	 		COMPARE:begin
	 			if(product[0] > product[1])begin
					Y_reg[c_counter + 1] <=	Y_reg[c_counter1 + 1];		
					Y_reg[c_counter1 + 1]<= Y_reg[c_counter + 1];
				end
				else begin
					Y_reg[c_counter] <=	Y_reg[c_counter];		
					Y_reg[c_counter1]<= Y_reg[c_counter1];
				end				
	 		end
	 		default:
	 			for (i = 0;i < 6; i = i + 1)
	 				Y_reg[i] <= Y_reg[i];	
	 	endcase  			
	 end
end


///////R_reg//////////////
always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	for (i = 0;i < 6; i = i + 1)
	 		R_reg[i] <= 0;
	 end
	 else begin
	 	case(c_state)
	 		IDLE:
	 			R_reg[0] <= R;
	 		TAKE:
	 			R_reg[c_counter] <= R;
	 		COMPARE:begin
	 			if(product[0] > product[1])begin
					R_reg[c_counter + 1] <=	R_reg[c_counter1 + 1];		
					R_reg[c_counter1 + 1] <= R_reg[c_counter + 1] ;
				end
				else begin
					R_reg[c_counter] <=	R_reg[c_counter];		
					R_reg[c_counter1]<= R_reg[c_counter1];
				end
	 		end
	 		default:
	 			for (i = 0;i < 6; i = i + 1)
	 				R_reg[i] <= R_reg[i];	
	 	endcase  			
	 end
end

//////counter///////////////
always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	c_counter <= 1;
	 end
	 else begin
	 	c_counter <= n_counter;
	 end
end 

always @(*)begin
	case(c_state)
		TAKE :
			n_counter = (c_counter == 4'd5) ? 0 : c_counter + 1;
		VECTOR:
			n_counter = (c_counter == 4'd4) ? 0 : c_counter + 1;
		COMPARE :begin
			if(c_counter1 == 4'd4) 
				n_counter = (c_counter == 4'd3) ? 0 : c_counter + 1;
			else 
				n_counter = c_counter;  
		end
		GEO2 :
			n_counter =  (c_counter == 4'd5) ? 0 : c_counter + 1;
		AREA_SIX :
			n_counter =  (c_counter == 4'd5) ? 1 : c_counter + 1;
		default:
			n_counter = c_counter;
	endcase
end

always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	c_counter1 <= 1;
	 end
	 else begin
	 	c_counter1 <= n_counter1;
	 end
end 
always @(*)begin
	case(c_state)
		COMPARE:
			n_counter1 = (c_counter1 == 4'd4) ? c_counter + 2 : c_counter1 + 1;
		AREA_SIX :
			n_counter1 = 1;
		default:
			n_counter1 = c_counter1;
	endcase
end

//////vector///////////////
always @(posedge clk or posedge reset)begin
	 if(reset)begin
	 	for (i = 0;i < 5; i = i + 1)begin
		 	X_vector[i] <= 0;
		 	Y_vector[i] <= 0;
		end
	 end
	 else begin
	 	case(c_state)
	 		VECTOR:begin
	 			X_vector[c_counter] <= X_reg[c_counter + 1] - X_reg[0];
	 			Y_vector[c_counter] <= Y_reg[c_counter + 1] - Y_reg[0];
	 		end
	 		COMPARE:begin
	 			if(product[0] > product[1])begin
					X_vector[c_counter]	 <=	X_vector[c_counter1];		
					Y_vector[c_counter]  <= Y_vector[c_counter1];
					X_vector[c_counter1] <=	X_vector[c_counter];		
					Y_vector[c_counter1] <= Y_vector[c_counter];
				end
	 		end
	 		default:
	 			for (i = 0;i < 5; i = i + 1)begin
				 	X_vector[i] <= X_vector[i];
				 	Y_vector[i] <= Y_vector[i];
				end
	 	endcase
	 end
end 

//////product///////////////
always @(posedge clk or posedge reset)begin
	if(reset)begin
	 	product[0] <= 0;
	 	product[1] <= 0;
	end
	else begin
	 	case(c_state)
	 		OUTER_PRODUCT: begin
	 			product[0] <= X_vector[c_counter] * Y_vector[c_counter1];
	 			product[1] <= X_vector[c_counter1] * Y_vector[c_counter];
	 		end
	 		SIDELENGTH : begin
	 			if (c_counter == 4'd5) begin
		 			product[0] <= ( X_reg[5] - X_reg[0] ) * ( X_reg[5] - X_reg[0] );
		 			product[1] <= ( Y_reg[5] - Y_reg[0] ) * ( Y_reg[5] - Y_reg[0] );
		 		end
		 		else begin
		 			product[0] <= ( X_reg[c_counter] - X_reg[c_counter + 1] ) * ( X_reg[c_counter] - X_reg[c_counter + 1] );
		 			product[1] <= ( Y_reg[c_counter] - Y_reg[c_counter + 1] ) * ( Y_reg[c_counter] - Y_reg[c_counter + 1] );		 			
		 		end
	 		end
	 		default: begin
			 	product[0] <= product[0];
			 	product[1] <= product[1];
	 		end
	 	endcase
	end
end 

		// 	if (c_counter == 4'd5) 
		// 		n_a = (s - R_reg[5]) * (s - R_reg[0]);
		// 	else
		// 		n_a = (s - R_reg[c_counter]) * (s - R_reg[c_counter + 1]);
		// end

always @(posedge clk or posedge reset)begin
	if(reset)begin
		product1 <= 0;
		product2 <= 0;
	end
	else begin
		case(c_state)
			GEO1_SIGN :begin
				product2 <= s;
				if((s-a) < 0)
	 				product1 <= ~(s-a) + 1;
	 			else
	 				product1 <= s-a;
		 	end
		 	GEO2_SIGN :begin
		 		if(c_counter == 4'd5)begin
			 		if((s-R_reg[5]) < 0)
		 				product1 <= ~(s - R_reg[5]) + 1;
		 			else
		 				product1 <= s - R_reg[5];
					if((s-R_reg[0]) < 0)
		 				product2 <= ~(s - R_reg[0]) + 1;
		 			else
		 				product2 <= s - R_reg[0];

		 		end
		 		else begin
			 		if((s-R_reg[c_counter]) < 0)
		 				product1 <= ~(s - R_reg[c_counter]) + 1;
		 			else
		 				product1 <= s - R_reg[c_counter];
					if((s-R_reg[c_counter + 1]) < 0)
		 				product2 <= ~(s - R_reg[c_counter +1 ]) + 1;
		 			else
		 				product2 <= s - R_reg[c_counter +1];
		 		end
		 	end
		 	default :begin
		 		product1 <=product1;
		 		product2 <=product2;
		 	end
		 endcase

	end
end
//////a///////////////////
always @(posedge clk or posedge reset)begin
	if(reset)begin
		a <= 0;
	end
	else begin
		case(c_state)
			SIDELENGTH1 :
				a <= root;
			GEO1:
				a <= root;
			default :
				a <= a;
		endcase
	end
end



always @(*)begin
	case(c_state)
		SIDELENGTH1 :
			n_a = product[0] + product[1];
		GEO1: begin
			n_a = product2 * product1 ;
		end
		GEO2:
			n_a = product2 * product1 ;
		default :
			n_a = 0;
	endcase
end

/////////////s////////////////
always @(posedge clk or posedge reset)begin
	if(reset)begin
		s <= 0; 
	end
	else begin
		case(c_state)
			SIDELENGTH1 :
				if (c_counter == 4'd5) 
					s <= (root + R_reg[5] + R_reg[0]) >> 1;
				else
					s <= (root + R_reg[c_counter] + R_reg[c_counter + 1]) >> 1;
			default:
				s <= s;
		endcase
	end
end

//////////////////area//////////////////////
always @(posedge clk or posedge reset)begin
	if(reset)begin
		area_tri <= 0;
	end
	else begin
		area_tri <= n_area_tri;
	end
end

always @(*)begin
	case(c_state)
		IDLE : begin
			n_area_tri = 0;
		end
		GEO2 : begin
	 		n_area_tri = root * a + area_tri; 
		end
		default :
			n_area_tri = area_tri;

	endcase
end

always @(posedge clk or posedge reset)begin
	if(reset)begin
		area_hex <= 0;
	end
	else begin
		area_hex <= n_area_hex;
	end
end

always @(*)begin
	case(c_state)
		IDLE : begin
			n_area_hex = 0;
		end
		AREA_SIX : begin
			if(c_counter == 4'd5)
	 			n_area_hex =( X_reg[0] * Y_reg[5] - X_reg[5] * Y_reg[0] + area_hex) >> 1 ; 
	 		else
	 			n_area_hex = X_reg[c_counter + 1] * Y_reg[c_counter] - X_reg[c_counter] * Y_reg[c_counter +1] + area_hex  ; 
		end
		default :
			n_area_hex = area_hex;

	endcase
end




/////////absolute_value


endmodule
