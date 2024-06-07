module TB;
	parameter ADDRSIZE = 4;
	parameter DATASIZE = 8;

    reg wclk, wpush, wrst_n;
    reg rclk, rpop, rrst_n;

    reg [DATASIZE - 1 : 0] wdata;

    wire wfull, rempty;

    wire [DATASIZE - 1 : 0] rdata;

        AFIFO myfifo (
			            .rdata(rdata),
			            .rempty(rempty),
			            .wfull(wfull),
			            .wpush(wpush),
			            .rpop(rpop),
			            .wclk(wclk),
			            .rclk(rclk),
			            .wdata(wdata),
			            .wrst_n(wrst_n),
			            .rrst_n(rrst_n)
        			);


    initial begin
        rclk = 0;
        forever #20 rclk = ~rclk;
    end

    initial begin
        wclk = 0;
        forever #30 wclk = ~wclk;
    end

    //波形显示
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, myfifo);
        $fsdbDumpon();
    end

    initial begin
        wpush = 0;
        rpop = 0;
        wrst_n = 1;
        rrst_n = 1;

        #10;
        wrst_n  = 0;
        rrst_n = 0;

        #20;
        wrst_n  = 1;
        rrst_n = 1;

        @(negedge wclk)
        wdata = {$random}%30;
        wpush = 1;

        repeat(7) begin
            @(negedge wclk)
            wdata = {$random}%30;
        end

        @(negedge wclk)
        wpush = 0;

        @(negedge rclk)
        rpop = 1;

        repeat(7) begin
            @(negedge rclk);
        end

        @(negedge rclk)
        rpop = 0;

        #150;

        @(negedge wclk)
        wpush = 1;
        wdata = {$random}%30;

        repeat(15) begin
            @(negedge wclk)
            wdata = {$random}%30;
        end

        @(negedge wclk)
        wpush = 0;

        #50;
        $finish;
    end

endmodule