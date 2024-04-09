`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output	reg [11:0]	iaddr,
	input		[19:0] idata,	
	
	output	reg	cwr,
	output	reg [11:0]	caddr_wr,
	output	reg [19:0]	cdata_wr,
	
	output	reg	crd,
	output	reg [11:0] 	caddr_rd,
	input	[19:0] 	cdata_rd,
	
	output	reg [2:0]	csel
	);
	
	reg signed [19:0] test,test1;
	reg signed [39:0] c_conv_data0, n_conv_data0, c_conv_data1, n_conv_data1;
	reg signed [19:0] con2 ,con3, con22,con33;
	reg [19:0] n_caddr_rd,n_cdata_wr;
	reg [3:0] c_state , n_state;
	reg n_busy;
	reg [11:0] n_iaddr;
	reg [11:0] c_gray_img_pos,n_gray_img_pos,n_caddr_wr; 
	reg [4:0] c_counter,n_counter;
	reg corner_test;
	reg pooling_sel,n_pooling_sel;
	reg signed [19:0] kernal1,kernal0;
	wire signed [39:0]kernal0_product,kernal1_product;
	parameter IDLE = 0, TAKE_DATA = 1, RELU = 2, RELU1 = 3, TRANS = 4 , POOLING = 5,TRANS1 = 6,
	SEL = 7,FLATTEN = 8,FLATTEN1 = 9,FLATTEN2 = 10,SEL1 = 11,FINISH = 12;
	integer i;

	assign kernal0_product = (kernal0 * $signed(idata & ({20{corner_test}}))) ;
	assign kernal1_product = (kernal1 * $signed(idata & ({20{corner_test}}))) ;	
//c_state
always @( posedge clk or posedge reset) begin
	if(reset)begin 
		c_state <= IDLE;
	end
	else begin
		c_state <= n_state;		
	end
end	

always @(*) begin
	case(c_state)
		IDLE : 
			n_state = TAKE_DATA;
		TAKE_DATA : 
			n_state = (c_counter == 5'd19) ? RELU : TAKE_DATA;
		RELU : 
			n_state = RELU1;
		RELU1 : 
			n_state = TRANS;
		TRANS :
			n_state = (c_gray_img_pos == 4095) ? POOLING : TAKE_DATA;
		POOLING :
			n_state = (c_counter == 4'd5) ? TRANS1 : POOLING;
		TRANS1 :
			n_state = (caddr_wr == 10'd1023) ? SEL : POOLING ;
		SEL :
			n_state = (pooling_sel == 1) ? FLATTEN : POOLING;
		FLATTEN :
			n_state = FLATTEN1;
		FLATTEN1 :
			n_state = FLATTEN2;
		FLATTEN2 :
			n_state = (caddr_rd == 1024)? SEL1 : FLATTEN;
		SEL1 :
			n_state = (pooling_sel == 0) ? FLATTEN : FINISH;
		FINISH :
			n_state = FINISH;
		default :
			n_state = c_state;
	endcase
end

//controll signal
always @(posedge clk or posedge reset) begin
	if(reset) begin
		busy <= 0; 
	end
	else begin
		case(c_state)
			IDLE :
				busy <= 1;
			TAKE_DATA :
				busy <= 1;
			RELU :
				busy <= 1;
			RELU1 :
				busy <= 1;
			TRANS :
				busy <= 1;
			POOLING :
				busy <= 1;
			TRANS1 :
				busy <= 1;
			SEL :
				busy <= 1;
			FLATTEN :
				busy <= 1;
			FLATTEN1 :
				busy <= 1;
			FLATTEN2 :
				busy <= 1;	
			SEL1 :
				busy <= 1;			
			default :
				busy <= 0;
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		pooling_sel <= 0; 
	end
	else begin
		pooling_sel <= n_pooling_sel;
	end
end

always @(*)begin
	case(c_state)
		SEL :
			n_pooling_sel <= (pooling_sel) ? 0 : 1;
		SEL1 :
			n_pooling_sel <= 1;
		default :
			n_pooling_sel <= pooling_sel;
	endcase
end
always @(posedge clk or posedge reset)begin
	if(reset)
		cwr <= 0;
	else begin
		case(c_state)
			RELU :
				cwr <= 1 ;
			RELU1 :
				cwr <= 1;
			POOLING :
				cwr <= (c_counter == 4'd5) ? 1 : 0;
			FLATTEN1 :
				cwr <= 1;
			default :
				cwr <= 0;
		endcase
	end
end

always @(posedge clk or posedge reset)begin
	if(reset)
		csel <= 3'b000;
	else begin
		case(c_state)
			RELU :
				csel <= 3'b001;
			RELU1 :
				csel <= 3'b010;
			POOLING : begin
				if(pooling_sel)
					csel <= (c_counter == 4'd5) ? 3'b100 : 3'b010 ;
				else	
					csel <= (c_counter == 4'd5) ? 3'b011 : 3'b001 ;
			end
			FLATTEN :
				csel <= (pooling_sel)? 3'b100 : 3'b011;
			FLATTEN1 :
				csel <= 3'b101;
			default :
				csel <= 3'b000;
		endcase
	end	
end


always @(posedge clk or posedge reset)begin
	if(reset)
		crd <= 3'b000;
	else begin
		case(c_state)
			POOLING :
				crd <= (c_counter == 4'd5) ? 0 : 1;
			FLATTEN :
				crd <= 1;
			default :
				crd <= 0;
		endcase
	end	
end

// iaddr
always @(posedge clk or posedge reset)begin
	if(reset) begin
		iaddr <= 0 ;
	end
	else begin
		case(c_state)
			TAKE_DATA :
				iaddr <= n_iaddr;
			default :
				iaddr <= 0;
		endcase
	end
end

always @(*)begin
	case (c_state)
		TAKE_DATA : 
			case(c_counter)
				5'd0 : 
					n_iaddr = c_gray_img_pos - 7'd65;
				5'd2 :
					n_iaddr = c_gray_img_pos - 7'd64;
				5'd4 :
					n_iaddr = c_gray_img_pos - 7'd63;
				5'd6 :
					n_iaddr = c_gray_img_pos - 7'd1;
				5'd8 :
					n_iaddr = c_gray_img_pos ;
				5'd10 :
					n_iaddr = c_gray_img_pos + 7'd1;
				5'd12 :
					n_iaddr = c_gray_img_pos + 7'd63;
				5'd14 :
					n_iaddr = c_gray_img_pos + 7'd64;
				5'd16 :
					n_iaddr = c_gray_img_pos + 7'd65;
				default :
					n_iaddr = iaddr;
			endcase
		default :
			n_iaddr = c_gray_img_pos;
	endcase
end


//caddr_rd
always @(posedge clk or posedge reset)begin
	if(reset)
		caddr_rd <= 0;
	else begin
		caddr_rd <= n_caddr_rd;
	end
end

always @(*)begin
	case(c_state)
		POOLING : 
			case(c_counter)
				4'd0 :
					n_caddr_rd = c_gray_img_pos;
				4'd1 :
					n_caddr_rd = c_gray_img_pos + 7'd1;
				4'd2 :
					n_caddr_rd = c_gray_img_pos + 7'd64;
				4'd3 :
					n_caddr_rd = c_gray_img_pos + 7'd65;
				default:
					n_caddr_rd = c_gray_img_pos;
			endcase
		SEL : 
			n_caddr_rd = (pooling_sel) ? 0 : caddr_rd;
		FLATTEN1 :
			n_caddr_rd =  caddr_rd + 1;
		SEL1 :
			n_caddr_rd = 0;
		default : 
			n_caddr_rd = caddr_rd;
	endcase
end



//gray_img_pos
always @(posedge clk or posedge reset) begin
	if(reset)begin
		c_gray_img_pos <= 0;
	end
	else 
		c_gray_img_pos <= n_gray_img_pos;
end

always @(*)begin
	case(c_state)
		TRANS :
			n_gray_img_pos = (c_gray_img_pos == 4095) ? 0 : c_gray_img_pos + 1 ;
		TRANS1 : begin
			if(c_gray_img_pos[5:0] == 6'b111110)
				n_gray_img_pos = c_gray_img_pos + 66;
			else
				n_gray_img_pos =  c_gray_img_pos + 2 ;
			end
		default :
			n_gray_img_pos = c_gray_img_pos;
	endcase
end

//caddr_wr
always @(posedge clk or posedge reset) begin
	if(reset)begin
		caddr_wr <= 0;
	end
	else 
		caddr_wr <= n_caddr_wr;
end

always @(*)begin
	case(c_state)
		TRANS :
			n_caddr_wr = (c_gray_img_pos == 4095) ? 0 : caddr_wr + 1 ;
		TRANS1 : 
			n_caddr_wr = caddr_wr + 1;
		SEL : 
			n_caddr_wr = (pooling_sel) ? 0 : caddr_wr;
		FLATTEN2 : 
			n_caddr_wr = (caddr_rd == 1024)? 1 : caddr_wr + 2;
		default :
			n_caddr_wr = caddr_wr;
	endcase
end



//counter
always @(posedge clk or posedge reset)begin
	if(reset) begin
		c_counter <= 0;
	end
	else begin
		c_counter <= n_counter;

	end
end

always @(*)begin
	case(c_state)
		TAKE_DATA :
			n_counter = (c_counter == 5'd19) ? 0 : c_counter + 1; 
		POOLING :
			n_counter = (c_counter == 4'd5) ? 0 : c_counter + 1;
		default :
			n_counter = c_counter;
	endcase
end

//cdata_wr
always @(posedge clk or posedge reset)begin
	if(reset)
		cdata_wr <=0;
	else
		cdata_wr <= n_cdata_wr;
end

always @(*) begin
	case(c_state)
		RELU : begin
			if(c_conv_data0[19] == 1 )
				n_cdata_wr = 0;
			else begin
				n_cdata_wr = c_conv_data0[19:0];
			end
		end
		RELU1 : begin
			if(c_conv_data1[19] == 1 )
				n_cdata_wr = 0;
			else begin
				n_cdata_wr = c_conv_data1[19:0];
			end
		end
		POOLING :
			n_cdata_wr = c_conv_data0[19:0];
		FLATTEN1 :
			n_cdata_wr = cdata_rd;
		default :
			n_cdata_wr = 0;

	endcase	
end

//conv_data

always @(posedge clk or posedge reset)begin
	if(reset)begin
		c_conv_data0 <= 0;
	end
	else begin
		c_conv_data0 <= n_conv_data0;
	end
end

always @(*)begin
	case(c_state)
		TAKE_DATA :
			case(c_counter)
				5'd2 : begin            
					n_conv_data0 =  c_conv_data0 + kernal0_product;
				end
				5'd4 : begin
					n_conv_data0 =  c_conv_data0 + kernal0_product;
					
				end
				5'd6 : begin
					n_conv_data0 =  c_conv_data0 + kernal0_product;
				end
				5'd8 : begin				
					n_conv_data0 =  c_conv_data0 + kernal0_product;					
				end 
				5'd10 : begin				
					n_conv_data0 =  c_conv_data0 + kernal0_product;
 				end
				5'd12 : begin
					n_conv_data0 =  c_conv_data0 + kernal0_product;					
				end
				5'd14 : begin
					n_conv_data0 =  c_conv_data0 + kernal0_product;							
				end
				5'd16 : begin
					n_conv_data0 =  c_conv_data0 + kernal0_product;
				end
				5'd18 : begin 
					n_conv_data0 =  c_conv_data0 + kernal0_product;	
				end
				5'd19 : begin
					con2  = {c_conv_data0[39] , c_conv_data0 [34:16]} + $signed(20'h01310);
					if(c_conv_data0[15] == 1)
						n_conv_data0 = con2 + 1;
					else 
						n_conv_data0 = con2 ;						
				end
				default : 
					n_conv_data0 = c_conv_data0;
			endcase
		TRANS :
			n_conv_data0 = 0;
		POOLING :
			case(c_counter)
				5'd0 :
					n_conv_data0 = 0;
				5'd1 : begin
					if(cdata_rd > c_conv_data0[19:0])
						n_conv_data0 = cdata_rd;
					else begin
						n_conv_data0 = c_conv_data0;
					end
				end
				5'd2 : begin
					if(cdata_rd > c_conv_data0[19:0])
						n_conv_data0 = cdata_rd;
					else begin
						n_conv_data0 = c_conv_data0;
					end
				end
				5'd3 : begin
					if(cdata_rd > c_conv_data0[19:0])
						n_conv_data0 = cdata_rd;
					else begin
						n_conv_data0 = c_conv_data0;
					end
				end
				5'd4 : begin
					if(cdata_rd > c_conv_data0[19:0])
						n_conv_data0 = cdata_rd;
					else begin
						n_conv_data0 = c_conv_data0;
					end
				end
				default:
					n_conv_data0 = c_conv_data0;
			endcase
		default :
			n_conv_data0 = c_conv_data0;
	endcase
end


//kernal1
//conv_data

always @(posedge clk or posedge reset)begin
	if(reset)begin
		c_conv_data1 <= 0;
	end
	else begin
		case(c_state)
			TAKE_DATA :
				c_conv_data1 <= n_conv_data1;
			default :
				c_conv_data1 <= n_conv_data1;
		endcase	
	end
end

always @(*)begin
	case(c_state)
		TAKE_DATA :
			case(c_counter)
				5'd2 : begin            
					n_conv_data1 =  c_conv_data1 + kernal1_product;
				end
				5'd4 : begin
					n_conv_data1 =  c_conv_data1 + kernal1_product;
					
				end
				5'd6 : begin
					n_conv_data1 =  c_conv_data1 + kernal1_product;
				end
				5'd8 : begin				
					n_conv_data1 =  c_conv_data1 + kernal1_product;					
				end 
				5'd10 : begin				
					n_conv_data1 =  c_conv_data1 + kernal1_product;
 				end
				5'd12 : begin
					n_conv_data1 =  c_conv_data1 + kernal1_product;					
				end
				5'd14 : begin
					n_conv_data1 =  c_conv_data1 + kernal1_product;							
				end
				5'd16 : begin
					n_conv_data1 =  c_conv_data1 + kernal1_product;
				end
				5'd18 : begin 
					n_conv_data1 =  c_conv_data1 + kernal1_product;	
				end
				5'd19 : begin
					con22  = {c_conv_data1[39] , c_conv_data1[34:16]} + $signed(20'hF7295);
						if(c_conv_data1[15])
							n_conv_data1 = con22 + 1;
						else 
							n_conv_data1 = con22 ;
				end
				default : 
					n_conv_data1 = c_conv_data1;
			endcase	
		TRANS :
			n_conv_data1 = 0;
		default :
			n_conv_data1 = c_conv_data1;

	endcase
end

always @(*)begin
	case(c_state)
		TAKE_DATA :
			case(c_counter)
				5'd1 : begin           
						kernal0 = 20'h0A89E;
				end
				5'd2 : begin
						kernal0 = 20'h0A89E;
				end
				5'd3 : begin
						kernal0 = 20'h092D5;
				end
				5'd4 : begin
						kernal0 = 20'h092D5;				
				end 
				5'd5 : begin				
						kernal0 = 20'h06D43;
 				end
				5'd6: begin
						kernal0 = 20'h06D43;						
				end
				5'd7: begin
						kernal0 = 20'h01004;					
				end
				5'd8: begin
						kernal0 = 20'h01004;
				end
				5'd9: begin 
						kernal0 = 20'hF8F71;	
				end
				5'd10: begin 
						kernal0 = 20'hF8F71;	
				end
				5'd11: begin 
						kernal0 = 20'hF6E54;	
				end
				5'd12: begin 
						kernal0 = 20'hF6E54;	
				end
				5'd13: begin 
						kernal0 = 20'hFA6D7;	
				end
				5'd14: begin 
						kernal0 = 20'hFA6D7;	
				end
				5'd15: begin 
						kernal0 = 20'hFC834;	
				end
				5'd16: begin 
						kernal0 = 20'hFC834;	
				end
				5'd17: begin 
						kernal0 = 20'hFAC19;	
				end
				5'd18: begin 
						kernal0 = 20'hFAC19;	
				end

				default : 
					kernal0 = 0;
			endcase	
		default :
			kernal0 = 0;

	endcase
end


always @(*)begin
	case(c_state)
		TAKE_DATA :
			case(c_counter)
				5'd1 : begin           
						kernal1 = 20'hFDB55;
				end
				5'd2 : begin
						kernal1 = 20'hFDB55;
				end
				5'd3 : begin
						kernal1 = 20'h02992;		
				end 
				5'd4 : begin				
						kernal1 = 20'h02992;
 				end
				5'd5 : begin
						kernal1 = 20'hFC994;			
				end
				5'd6 : begin
						kernal1 = 20'hFC994;					
				end
				5'd7 : begin
						kernal1 = 20'h050FD;
				end
				5'd8 : begin 
						kernal1 = 20'h050FD;
				end
				5'd9 : begin 
						kernal1 = 20'h02F20;
				end
				5'd10 : begin 
						kernal1 = 20'h02F20;
				end
				5'd11 : begin 
						kernal1 = 20'h0202D;
				end
				5'd12 : begin 
						kernal1 = 20'h0202D;
				end
				5'd13 : begin 
						kernal1 = 20'h03BD7;
				end
				5'd14 : begin 
						kernal1 = 20'h03BD7;
				end
				5'd15 : begin 
						kernal1 = 20'hFD369;
				end
				5'd16 : begin 
						kernal1 = 20'hFD369;
				end
				5'd17 : begin 
						kernal1 = 20'h05E68;
				end
				5'd18 : begin 
						kernal1 = 20'h05E68;
				end				
				default : 
					kernal1 = 0;
			endcase	
		default :
			kernal1 = 0;

	endcase
end


always @(posedge clk or posedge reset )begin
	if(reset)begin
		corner_test <= 0;
	end
	else begin
		case(c_state)
			TAKE_DATA :
				case(c_counter)
					5'd1 : begin            
						if(c_gray_img_pos < 64 || c_gray_img_pos[5:0] == 0)begin
							corner_test <= 0;
						end
						else begin
							corner_test <= 1;
						end
					end
					5'd3 : begin
						if(c_gray_img_pos < 64)begin
							corner_test <= 0;
						end
						else begin
							corner_test <= 1;
						end
					end
					5'd5 : begin
						if(c_gray_img_pos < 64 || c_gray_img_pos[5:0] == 6'b111111)begin
							corner_test <= 0;
						end
						else begin
							corner_test <= 1;
						end
					end
					5'd7 : begin
						if(c_gray_img_pos[5:0] == 0)begin
							corner_test <= 0;
						end
						else begin
							corner_test <= 1;
						end				
					end 
					5'd9 : begin				
							corner_test <= 1;
	 				end
					5'd11: begin
						if(c_gray_img_pos[5:0] == 6'b111111)begin
							corner_test <= 0;
						end
						else begin
							corner_test <= 1;
						end					
					end
					5'd13: begin
						if(c_gray_img_pos[5:0] == 0 || c_gray_img_pos > 12'd4031)begin
							corner_test <= 0;
						end
						else begin
							corner_test <= 1;
						end					
					end
					5'd15: begin
						if(c_gray_img_pos > 12'd4031)begin
							corner_test <= 0;
						end
						else begin
							corner_test <= 1;
						end
					end
					5'd17: begin 
						if(c_gray_img_pos > 12'd4031 || c_gray_img_pos[5:0] == 6'b111111)begin
							corner_test <= 0;
						end
						else begin
							corner_test <= 1;
						end	
						
					end
					default : 
						corner_test <= corner_test;
				endcase
		endcase
	end
end


endmodule


