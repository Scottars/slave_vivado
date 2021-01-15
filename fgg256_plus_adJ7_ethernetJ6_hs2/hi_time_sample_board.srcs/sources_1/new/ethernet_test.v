`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ethernet_test
// 描述：此程序用于千兆以太网udp通信测试，千兆以太网通信时，FPGA和RTL8211之间通信接口为GMII
//      此程序不适用百兆以太网数据通信，百兆以太网MII接口udp通信的程序参考ethernet_100
//////////////////////////////////////////////////////////////////////////////////
module ethernet_test(
				
                  input sys_clk_50M,
                  
                  input ext_bcode,
         
//					output  fpga_clk,     // 了解pfpaclk 的作用是干嘛的               
					output reg  user_led_board,
					output   user_led_green,
					output reg  user_led_yellow,
					
					input  seq_1,
					
					(*mark_debug= "true"*)input [11:0] ad1_data,
					(*mark_debug= "true"*)input [11:0] ad2_data,
					output       ad1_clk,
					output       ad2_clk,
					output       test_ad_clk,
				  
				   output e_reset,
                   output e_mdc,                      //MDIO的时钟信号，用于读写PHY的寄存器
				   inout  e_mdio,                     //MDIO的数据信号，用于读写PHY的寄存器
		
            
					input	 e_rxc,                      //125Mhz ethernet gmii rx clock  phy 到mac， 用了125M的系统时钟，当作时钟。
					input	 e_rxdv,	                    //GMII 接收数据有效信号    phy到mac
					input	 e_rxer,	                    //GMII 接收数据错误信号				  phy 到mac	
					input  [7:0] e_rxd,                //GMII 接收数据	          phy到mac

					input	 e_txc,                      //25Mhz ethernet mii tx clock   phy芯片发送到mac        
					output e_gtxc,                     //25Mhz ethernet gmii tx clock   mac提供gtxc
					output e_txen,                     //GMII 发送数据有效信号	      mac 发送到phy
					//output e_txer,                     //GMII 发送数据错误信号		 mac 层发送到phy
					output [7:0] e_txd	              //GMII 发送数据      mac 到phy
  
    );

wire sys_clk;
wire clk_200M;
wire clk_125M;
wire clk_25M;
wire clk_10M;
wire clk_5M;
clk_wiz_0 pll_unit(
    .clk_in1(sys_clk_50M),
    .clk_out1(clk_200M),
    .clk_out2(clk_125M),
    .clk_out3(clk_25M),
    .clk_out4(clk_5M)
);
assign sys_clk = clk_200M;

// 表示系统正在运行指示灯
reg [31:0]timer_led;
initial begin
timer_led <=0;
end
always @(posedge sys_clk)
begin
    if(timer_led == 32'd200_000_000)
        begin
            user_led_board <=1'b0;
            user_led_yellow <=1'b0 || ~seq_1; // 这个时候才是亮光的时候
                                                   // 正在进行数据的发送， 这个结果输出是低电平才有光。
                                                 //当无seq_1的时候，此时，过来的为低电平，此时就应该一直输出高电平，使得灯光一直不亮。
                                                 //当有seq_1的时候，此时，来的为高电平，此时就应该输出高低电平的交互，使得灯光受到user_led_yellow 的控制
            timer_led <= 32'd0;
        end
    else if(timer_led == 32'd100_000_000)
        begin
            timer_led <= timer_led + 1;
            user_led_board <=1'b1;
            user_led_yellow <=1'b1;
 

        end
    else
        timer_led <= timer_led + 1;
end

//assign ram_rdy= ram_rdy & seq_1; // 不进行以太网的数据发送，其即是当有光的时
//assign user_led_yellow  = seq_1;




wire rst;
assign rst=1'b1;
//input ext_bcode;
wire [16:0] sbs;
wire [19:0] cnt_us;
wire clk_1m;
readbcode u3(
.clk(sys_clk), 
.rst_n(rst),//复位信号
.bcode0(ext_bcode),//外部B码输入
.sbs_reg(sbs),
.cnt_us(cnt_us),
.clk_1m(clk_1m),//读B码得到的17位秒码
.user_led_green(user_led_green)
);

///b code simulationm 
//输出一个cnt_us 输出一个 sbs
//reg [19:0] cnt_us;
//reg [16:0] sbs;
//reg [31:0] sim_bcode_i=32'b0;
//always@(posedge sys_clk)
//begin
//    if (sim_bcode_i==32'd200_000_000) begin
//        sim_bcode_i<= 0;
//        sbs<= sbs+17'd1;
//    end
//    else if(sim_bcode_i==32'd190_000_000) begin  
//        sim_bcode_i<= sim_bcode_i + 1'b1;
//    end
//    else
//        sim_bcode_i<= sim_bcode_i + 1'b1;    
//end
//reg [31:0] sim_cnt_us_i=32'b0;
//always@(posedge sys_clk)
//begin
//    if(cnt_us == 32'd1000000)begin
//        cnt_us <= 20'b0;
//    end
//    else if (sim_cnt_us_i==32'd200) begin
//        cnt_us<=cnt_us + 1'b1;
//        sim_cnt_us_i<= 0;
//    end
//    else begin
//        sim_cnt_us_i<= sim_cnt_us_i + 1'b1;
//    end    
//end



wire e_txer;
wire [31:0] ram_wr_data;
wire [9:0] ram_wr_addr;

reg reset_n=1'b1;

assign e_gtxc=e_rxc;
 
assign e_reset = 1'b1; 
//assign e_txer =1'b0;
wire [31:0] datain_reg;
         
wire [3:0] tx_state;
wire [3:0] rx_state;
wire [15:0] rx_total_length;          //rx 的IP包的长度
wire [15:0] tx_total_length;          //tx 的IP包的长度
wire [15:0] rx_data_length;           //rx 的UDP的数据包长度
wire [15:0] tx_data_length;           //rx 的UDP的数据包长度

wire data_receive;
reg ram_wr_finish;

reg [31:0] udp_data [4:0];                        //存储发送字符
reg ram_wren_i;
reg [9:0] ram_addr_i;
reg [31:0] ram_data_i;
reg [9:0] i;

wire data_o_valid;
wire wea;
wire [9:0] addra;
wire [31:0] dina;
//说明，当前是数据data o valid 的话，此时则 wr finsh 无效， 则不能开始写ram  
//assign wea=ram_wr_finish?data_o_valid:ram_wren_i;          //ram 写使能信号选择  
//assign addra=ram_wr_finish?ram_wr_addr:ram_addr_i;         //ram 写地址选择gi
//assign dina=ram_wr_finish?ram_wr_data:ram_data_i;          //ram 写数据选择  

//assign wea=ram_wren_i;          //ram 写使能信号选择  
assign wea=1;          //ram 写使能信号选择  
assign addra=ram_addr_i;         //ram 写地址选择gi
assign dina=ram_data_i;          //ram 写数据选择  


assign tx_data_length=16'd816;  //（---------------------------- ------------- udp2+2  + 2 +2   +data（2+1+1+4+400+400） + fcs   
assign tx_total_length=16'd836;//这个地方不包括以太网）以太网 6+6+2    ip20
(*mark_debug ="true"*)wire ram_rdy;
(*mark_debug ="true"*)reg ram_rdy1=1'b0;
(*mark_debug ="true"*)reg ram_rdy2=1'b0;
(*mark_debug ="true"*)wire [9:0] ram_rd_addr;
(*mark_debug ="true"*)wire [31:0]ram_rd_data;
////////udp发送和接收程序/////////////////// 
udp u1(
	.reset_n(reset_n),
	.e_rxc(e_rxc),
	.e_rxd(e_rxd),
   .e_rxdv(e_rxdv),
	.e_txen(e_txen),
	.e_txd(e_txd),
	.e_txer(e_txer),		
	
	.data_o_valid(data_o_valid),                    //数据接收有效信号,写入RAM/
	.ram_wr_data(ram_wr_data),                      //接收到的32bit数据写入RAM/	
	.rx_total_length(rx_total_length),              //接收IP包的总长度/
	.rx_state(rx_state),                            //for chipscope test
	.rx_data_length(rx_data_length),                //接收IP包的数据长度/	
	.ram_wr_addr(ram_wr_addr),                      //ram写数据地址
	.data_receive(data_receive),                    //接收到以太网数据包标志
	
	.rdy1(ram_rdy1),
    .rdy2(ram_rdy2),
	.ram_rd_data(ram_rd_data),                      //RAM读出的32bit数据/
	.tx_state(tx_state),                            //for chipscope test

	.tx_data_length(tx_data_length),                //发送IP包的数据长度/	
	.tx_total_length(tx_total_length),              //接发送IP包的总长度/
	.ram_rd_addr(ram_rd_addr)                       //ram读数据地址

	);




reg [31:0] ad_clk_i;
reg clk_1M;
always @(posedge sys_clk)
begin
    if(ad_clk_i==200)
    begin
        ad_clk_i <= 0;
        clk_1M<=1'b0;
    end
    else if(ad_clk_i==100)
        begin
            ad_clk_i <= ad_clk_i + 1;
           clk_1M <= 1'b1;   
        end   
    else
        ad_clk_i <= ad_clk_i + 1;
end




/////////////ad ltc2290 part//////////////////////////
assign ad1_clk = clk_1m &&  seq_1;
assign ad2_clk = clk_1m && seq_1;
assign test_ad_clk = clk_1m;

(*mark_debug ="true"*)wire[31:0] cha_data;
(*mark_debug ="true"*)wire[31:0] chb_data;

(*mark_debug ="true"*)wire store_en;
ltc2290 ltc2290(
.clk(e_rxc),    //125M时钟
.ad_clk(ad1_clk),//A、B通道共用一个时钟1MHz/us产生
.da(ad1_data),
.db(ad2_data),//AD数据
.cha_data(cha_data),
.chb_data(chb_data),
.store_en(store_en)
);

//(*mark_debug ="true"*)reg store_en;
//reg [31:0] store_en_test_i;
//always@(posedge e_rxc)
//begin
//    if(store_en_test_i==32'd125)
//    begin
//        store_en_test_i <= 32'd0;
//    end
//    else if(store_en_test_i==32'd120) begin 
//        store_en_test_i <= store_en_test_i+1;
//        store_en <= 1'b0;
//    end
//    else if(store_en_test_i==32'd110) begin 
//        store_en_test_i <= store_en_test_i+1;
//        store_en <= 1'b1;
//        end
//    else if (store_en_test_i==32'd100)begin
//        store_en_test_i <= store_en_test_i+1;
//    end else
//        store_en_test_i <= store_en_test_i+1;
    

//end






/////////////////////////////////////////////ram store part////////////

//reg cnt_us;
//reg sbs;
ram_store ram_store(
.clk(e_rxc),
.cha_data(cha_data),
.chb_data(chb_data),
.cnt_us(cnt_us),
.sbs(sbs),
.store_en(store_en), // ltc2290 模块传输给ram存储部分
.eth_rd_addr(ram_rd_addr),
.eth_rd_data(ram_rd_data),
.seq_1(seq_1),
.ram_rdy(ram_rdy)
);   


///// 这种方法 只需要严格计算好延时的时间，即可正常的对接接口

(*mark_debug ="true"*)reg [2:0] ram_state;     
parameter ram_state_idle=3'b000,ram_state_rdy1 = 3'b001,ram_state_rdy2 = 3'b010;
(*mark_debug ="true"*)reg [31:0]ram_switch_i;
//always@(posedge e_rxc)
//begin
//    if(ram_switch_i==tx_total_length+ 100)
//    begin
//        ram_switch_i <= 32'd0;
//    end
//    else if(ram_switch_i==32'd20) begin 
//        ram_switch_i <= ram_switch_i+1;
//        ram_rdy1 <= 1'b0;
//    end
//    else if(ram_switch_i==32'd10) begin 
//        ram_switch_i <= ram_switch_i+1;
//        ram_rdy1 <= 1'b1;
//        end
//    else 
//      ram_switch_i <= ram_switch_i+1;

//end


//上传速度设定以及计算方案
//设定两级速度
//ad 的采样速度1M，进行累计100个进行数据的发送


always@(posedge e_rxc)
begin
case(ram_state)
ram_state_idle:begin
    if(ram_rdy == 1)
        ram_state <= ram_state_rdy1;
    else
        ram_state <=ram_state_idle;
end
ram_state_rdy1:begin // 这个是等待以太网再次进入idle 
    if(ram_switch_i==(tx_total_length+100))begin
         ram_switch_i <= 0;
        ram_state <= ram_state_rdy2;
    end
    else if(ram_switch_i == 10)begin
        ram_rdy1 <=1'b0;
        ram_rdy2 <=1'b0;
        ram_switch_i<= ram_switch_i  + 1;  
    end
    else if(ram_switch_i == 0) begin
        ram_switch_i<= ram_switch_i  + 1;  
        ram_rdy1 <=1'b1;
        ram_rdy2 <=1'b0;
    end
    else begin
            ram_switch_i<= ram_switch_i  + 1;  
    end
end
ram_state_rdy2:begin
    if(ram_switch_i==(tx_total_length+100))begin
         ram_switch_i <= 0;
            ram_state <= ram_state_idle;
   end
   else if(ram_switch_i == 10)begin
        ram_switch_i<= ram_switch_i  + 1;  
       ram_rdy1 <=1'b0;
       ram_rdy2 <=1'b0;
   
   end
   else if(ram_switch_i == 0) begin
           ram_switch_i<= ram_switch_i  + 1;  
           ram_rdy1 <=1'b0;
           ram_rdy2 <=1'b1;
   end
   else begin
       ram_switch_i<= ram_switch_i  + 1;  
   end
end
endcase
end





endmodule
