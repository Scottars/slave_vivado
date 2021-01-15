module ram_store(
input clk,//用125M以太网时钟/恒温晶振倍频时钟
input [31:0] cha_data,
input [31:0] chb_data,//AD数据：浮点数表示的实际电压值
input [31:0] cnt_us,
input [31:0] sbs,
input store_en,//存储使能
//input [8:0]rd_addr,
//均送入以太网发送模块
input seq_1,
input [9:0] eth_rd_addr,
output [31:0] eth_rd_data,//ram输出
output reg ram_rdy
//output reg ram_rdy1,
//output reg ram_rdy2
);


reg wr_en=0;
//这个addr 自己切换和计算
reg [9:0]wr_addr;
reg [31:0] wr_data; 


    
    
//ram ram_inst1 (
//.clka(clk),           // input clka
//.wea(wr_en),     // input [0 : 0] wea
//.addra(wr_addr),    // input [8 : 0] addra
//.dina(wr_data),     // input [31 : 0] dina
//.clkb(clk),           // input clkb
//.addrb(eth_rd_addr),    // input [8 : 0] addrb
//.doutb(eth_rd_data)     // output [31 : 0] doutb
//);  

///////////双 ram切换部分////////////////



wire [9:0] eth_rd_addr1;
wire [31:0] eth_rd_data1;
wire [9:0] eth_rd_addr2;
wire [31:0] eth_rd_data2;
// 对于ram_switch_signal的切换，采用每次完成100次存储后进行切换啊
(*mark_debug ="true"*)reg ram_switch_signal=1'b1;
(*mark_debug ="true"*)wire wr_en1;
(*mark_debug ="true"*)wire wr_en2;
(*mark_debug ="true"*)wire rd_en1;
(*mark_debug ="true"*)wire rd_en2;

assign wr_en1 =ram_switch_signal? wr_en:1'b0;
assign wr_en2 =ram_switch_signal? 1'b0:wr_en;
assign rd_en1 =ram_switch_signal? 1'b0:1'b1;
assign rd_en2 =ram_switch_signal? 1'b1:1'b0;
assign eth_rd_addr1 =ram_switch_signal? 9'd0:eth_rd_addr;
assign eth_rd_addr2 =ram_switch_signal? eth_rd_addr:9'd0;
assign eth_rd_data =ram_switch_signal? eth_rd_data2:eth_rd_data1;
 
ram ram_inst3 (
.clka(clk),           // input clka
.wea(wr_en1),     // input [0 : 0] wea
.addra(wr_addr),    // input [8 : 0] addra
.dina(wr_data),     // input [31 : 0] dina
.clkb(clk),           // input clkb
.enb(rd_en1),
.addrb(eth_rd_addr1),    // input [8 : 0] addrb
.doutb(eth_rd_data1)     // output [31 : 0] doutb
);

ram ram_inst2 (
.clka(clk),           // input clka
.wea(wr_en2),     // input [0 : 0] wea
.addra(wr_addr),    // input [8 : 0] addra
.dina(wr_data),     // input [31 : 0] dina
.clkb(clk),           // input clkb
.enb(rd_en2),
.addrb(eth_rd_addr2),    // input [8 : 0] addrb
.doutb(eth_rd_data2)     // output [31 : 0] doutb
);



reg [9:0]i;
// 三个状态， 存储a  存储b

parameter idle=4'd0,pre_judge=4'd1,us_judge=4'd2,write_cha =4'd3,write_usa =4'd4,write_chb = 4'd5,write_usb =4'd6,wait_to_100=4'd7,write_cha_head1=4'd8,write_cha_head2=4'd9,write_chb_head1=4'd10,write_chb_head2=4'd11,en_eth=4'd12;
(*mark_debug ="true"*)reg [3:0]state = idle;
(*mark_debug ="true"*)reg [9:0]cha_addr=2;
(*mark_debug ="true"*)reg [9:0]chb_addr=252;
reg ts_flag;
reg [31:0] reg_us;
(*mark_debug ="true"*)reg [7:0] cnt=8'd0;
(*mark_debug ="true"*)reg [7:0] ts_cnt;
//reg ram_rdy=1'b0;
always@(posedge clk )
begin
case(state)
idle:begin
    wr_en <=1'b0;
    wr_addr<=9'b0;    
    if(store_en) begin
        state <= pre_judge;
//        if(cnt==8'd99) begin
//           cnt<=8'd0;
           
//		   reg_us<=32'd0;//马上开始新一轮发送，缓存的us时标应该先归零，不然可能误判（上一轮最后us=1M-1,本轮第一个us=0，就会误判为跨秒）
//        end
//        else begin
//           cnt<=cnt+1'b1;
//        end
    end
       
end

pre_judge:begin
 if(ts_flag)//已检测出跨秒
     state<=write_cha;//跳过us判断（因为一组数据里不会有2次跨秒）
 else
     state<=us_judge;
end

//判断本次us值与上次us值：若本次us<上次us，说明跨秒（因为采样是连续的，连续两个采样值之间间隔小于1s，所以跨秒的us肯定小于上一个us）
us_judge:begin
  reg_us<=cnt_us;//reg_us用于缓存上一次存储的us值
  if(cnt_us<reg_us)//本次us<上次us：该数据是跨秒数据  SCottar， 实际上，对于cnt_us 而言，其范围就是0-1 000 000 -1  即99999
//  if(cnt_us ==0) 
    begin
        ts_cnt<=(cha_addr>>1) - 1;//本秒数据个数ts_cnt就等于当前已存储数据个数cnt
//        ts_cnt<=cnt-1;//本秒数据个数ts_cnt就等于当前已存储数据个数cnt
		ts_flag<=1'b1;//已检测出跨秒指示：ts=this second
		state<=write_cha;
	 end
   else begin 
      ts_cnt <= 8'd100;
      ts_flag<=1'b0;//未检测出跨秒
      state<=write_cha;
    end
      
       
end



///检测数据存满信号，若存满，则将给出发送信息
write_cha:begin
        wr_en <= 1'b1;
        wr_addr <= cha_addr+1;
        wr_data <=  cha_data;
//        wr_data <= 32'h0000_00000;
        state <= write_usa;
end

write_usa:begin
        wr_en <= 1'b1;
        wr_addr <= cha_addr+2;
        wr_data <= cnt_us;
//        wr_data <= 32'h0000_0000;
        state <= write_chb;
end

write_chb:begin
        wr_en <= 1'b1;
        wr_addr <= chb_addr+1;
        wr_data <= chb_data;
        state <= write_usb;
end
write_usb:begin
        wr_en <= 1'b1;
        wr_addr <= chb_addr+2;
        wr_data <= cnt_us;
//        wr_data <= 32'h6000_6000;
        state <= wait_to_100;
end
wait_to_100:begin
    cha_addr  <= cha_addr+2;
   chb_addr  <= chb_addr+2;
   cnt <= cnt + 1'b1;
    wr_en  <=1'b0;
    if (cha_addr == 200)begin
        cnt<=8'd0;
        reg_us<=32'd0;
        
        cha_addr  <= 0;
        chb_addr  <= 250;
        state<=write_cha_head1;
    end
    else 
        state<=idle;
end
write_cha_head1:begin
    wr_addr <= 1;
    wr_data <= {16'd7,8'd100,ts_cnt};
//        wr_data <= {16'd1,8'd100,8'd200};
    wr_en =1'b1;
    state<=write_cha_head2;
end
write_cha_head2:begin
    wr_addr <= 2;
    if(ts_flag)
        wr_data <= sbs-1;
    else
        wr_data <= sbs;
    
    wr_en =1'b1;
    state<=write_chb_head1;

end
write_chb_head1: begin
    wr_addr <= 251;
    wr_data <= {16'd8,8'd100,ts_cnt};
//    wr_data <= {16'd2,8'd100,8'd200};
    wr_en =1'b1;
    state<=write_chb_head2;
end
write_chb_head2:begin
    wr_addr <= 252;
        if(ts_flag)
        wr_data <= sbs-1;
    else
        wr_data <= sbs;
    wr_en =1'b1;
    state<=en_eth;
end
//等几个时钟，将这个位数变化让以太网部分能够监测到
en_eth:begin
    if(i==4) begin
        i<=0;
        ram_rdy=0;
        ts_flag<=0;//跨秒指示回零
        ram_switch_signal <= ~ram_switch_signal; 
        state <= idle;
    end
    else begin
//        if(ts_flag) begin 
            wr_en<=1'b0;
//            ram_rdy <= 1'b1;
            ram_rdy <= 1'b1 && seq_1;
//        end
//        else begin
//            wr_en<=1'b0;
//            ram_rdy <= 1'b0;
//        end
        
        i <= i+ 1;
    end
end

endcase
end



endmodule
