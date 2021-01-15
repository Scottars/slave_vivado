`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/30 17:24:21
// Design Name: 
// Module Name: readbcode
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

(* DONT_TOUCH= "TRUE" *)
module readbcode(clk,bcode0,rst_n,sbs_reg,cnt_us,clk_1m,user_led_green);
input clk;//200M
//(*mark_debug="true"*)input bcode;//输入B码
(*mark_debug="true"*)input bcode0;//输入B码
input rst_n;//复位
(*mark_debug="true"*)output reg [16:0] sbs_reg;//17位sbs码
(*mark_debug="true"*)output reg [19:0] cnt_us=20'd999999;
(*mark_debug="true"*)output reg clk_1m;
output reg user_led_green;



(*mark_debug="true"*)reg [31:0] cnt,width1,width2;//width1为前一个码元的脉宽，width2为当前码元脉宽,认为：15~25即为2ms,45~55即为5ms,75~85即为8ms
reg bbuf,brise;//上升沿检测
reg bbuf1,bfall;//下降沿检测
reg state;//case中的状态
reg [6:0] num;//码元计数值，0~99
reg [4:0] i;//time_bcd[i]赋值，0~29
reg binary;//表示二进制1/0
reg head;//B码首部Pr码元指示
(*mark_debug="true"*)reg [16:0] sbs;

parameter fre=8'd200;//fre=时钟频率/1M---计数fre对应时长为1us
parameter c2ms_low=32'd350000;
parameter c2ms_high=32'd450000;//计数2ms理论计数值为200*2000=400000
parameter c5ms_low=32'd950000;
parameter c5ms_high=32'd1050000;
parameter c8ms_low=32'd1550000;
parameter c8ms_high=32'd1650000;

//assign test=1'b1;
reg [31:0] cnt22=32'd0;
always @(posedge clk)
begin
   if(cnt22<100000000) begin
      cnt22<=cnt22+1'b1;
   end
   else begin
      cnt22<=32'd0;
   end
end

initial begin
i=0;
state=0;
width1=0;
width2=0;
cnt=0;
num=0;
head=0;
sbs_reg=0;
end
//丢失模拟
reg bcode,bcode1;
//assign bcode=lost_switch?0:bcode0;
//assign bcode=bcode0;

always @(posedge clk)
begin
bcode1<=bcode0;
bcode<=bcode1;
end

//检测B码脉冲上升沿
always @(posedge clk)
begin
 bbuf<=bcode;
 brise<=bcode&(~bbuf);
end




//检测B码脉冲下降沿
always @(posedge clk)
begin
 bbuf1<=bcode;
 bfall<=(~bcode)&bbuf1;
end

//脉宽计数
always @(posedge clk)
begin
  if(!rst_n)//复位信号，低电平有效
     begin
	    cnt<=0;	
		 width1<=0;
		 width2<=0;
	  end
  else begin
    if(bcode)//高电平时，进行脉宽计数
       cnt<=cnt+1;
    else if(bfall)//下降沿时计数清零，准备进行下一次计数；同时，对两个脉宽进行赋值
	    begin
		 width1<=width2;//将上一个码元脉宽值赋给width1
		 width2<=cnt;//将当前值赋给width2
		 cnt<=0;//计数清零
		 end
  end
end


//state 0、1：先脉宽--二进制转换，再进行码元计数(采用case语句只是为了方便建立一个先后顺序)
always @(posedge clk)
begin
if(!rst_n)
 begin
  state<=0;
  head<=1'b0;
  binary<=1'b0;
 end
 
else begin
case(state)
1'b0:begin//在每个B码上升沿进行脉宽--二进制以及帧头判断
  if(brise)
    begin
     if((width2>c8ms_low)&&(width1>c8ms_low))//连续两个脉宽为8ms
		  head<=1'b1;//帧头Pr
	  else if((width2>c5ms_low)&&(width2<c5ms_high))//脉宽为5ms，对应二进制1,binary置1
	     begin
		  binary<=1'b1;
		  	  head<=1'b0;	
		  end
		else if((width2>c2ms_low)&&(width2<c2ms_high))//脉宽为2ms，对应二进制0，binary置0
		   begin
		     binary<=1'b0;
		  	  head<=1'b0;	
		   end
		 else
		  head<=1'b0;	
	state<=1'b1;//跳到下一步
	 end
  else
    state<=1'b0;
	end


1'b1:begin//码元计数
	if(head)//检测到帧头后，此时为1号码元的上升沿，width2为Pr的脉宽，将码元计数值置0
	    num<=0;
	  else 
	     begin
	    num<=num+1;
		  end
   state<=0;//回到状态0		
	end
endcase	
 end
end

//B码丢失判断
//head上升沿判断
reg head_buf,head_rise;
always @(posedge clk)
begin
  head_buf<=head;
  head_rise<=head&(~head_buf);
end

(*mark_debug="true"*)reg [31:0] bcnt=0;
always @(posedge clk)
begin
   if( head_rise)
     bcnt<=bcnt+1'b1;
end


//head上升沿后，延时产生一个判断窗:若在该窗内未出现B码上升沿，则认为B码丢失
reg [31:0] jcnt;
(*mark_debug="true"*)reg lost;
reg [1:0] jstate;
parameter idle=2'd0,count=2'd1,jstart=2'd2;
parameter jlow=32'd199800000;
parameter jhigh=32'd200200000;//判断窗位置:延时999ms~1001ms

initial begin
 lost=1'b1;
end
always @(posedge clk)
begin
    user_led_green <= ~lost; // 
end

always @(posedge clk)
begin
case(jstate)
idle:begin
  if(head_rise)//1号码元上升沿
     begin
       jstate<=count;
       lost<=1'b0;
       jcnt<=32'd0;
     end
end 
//延时计数
count:begin
     jcnt<=jcnt+1'd1;
     if(jcnt==jlow)
       jstate<=jstart;
end
//判断窗开始
jstart:begin
 if(jcnt<jhigh) begin
   jcnt<=jcnt+1'd1;
    if(head_rise)
      begin
        lost<=1'b0;
        jstate<=count;
        jcnt<=32'd0;
      end
 end
 
 else
   begin
     lost<=1'b1;//丢失指示
     jstate<=idle;
     jcnt<=32'd0;
   end  
end

default:begin
   jstate<=idle;
   jcnt<=32'd0;
   lost<=1'b1;
end
endcase
end

//B码未丢失时,通过B码Pr起始标志延时产生秒脉冲
(*mark_debug="true"*)reg b_pps;
reg [31:0] cnt2=0;
reg state_bpps;
parameter wait1=1'b0,delay1=1'b1;//wait为verilog的keyword
parameter cnt2_negegde=32'd100000000;//在该计数值产生秒脉冲下降沿,可调整该计数值以调整秒脉冲占空比
parameter cnt2_posedge=32'd197999999;//在head_rise即1号码元上升沿后，延时990ms产生秒脉冲上升沿
always @(posedge clk)
begin
case(state_bpps)
wait1:begin
  if(head_rise)
    begin
      cnt2<=32'd0;
      state_bpps<=delay1;
    end
end

delay1:begin
  if(cnt2==cnt2_negegde)
         begin
           b_pps<=1'b0;
           cnt2<=cnt2+1'd1;
         end
  else if(cnt2==cnt2_posedge)
         begin
           b_pps<=1'b1;
           state_bpps<=wait1;
         end
  else
      cnt2<=cnt2+1'd1;
end

default:begin
 b_pps<=1'b0;
 cnt2<=32'd0;
 state_bpps<=wait1;
end    
endcase
end

//lost=0时,在b_pps基础上，通过晶振计数延时来产生秒脉冲d_pps；在B码lost后，在d_pps基础上进行守时
//检测到lost后，首先在lost检测的基础通过延时产生第一个d_pps,之后通过晶振1s计数产生一系列的秒脉冲d_pps

//检测lost上升沿、下降沿，指示B码丢失、恢复
reg lbuf=1,lrise,lfall;
always @(posedge clk)
begin
 lbuf<=lost;
 lrise<=lost&(~lbuf);
 lfall<=(~lost)&lbuf;
end

//守时：本地晶振循环计数产生秒脉冲
(*mark_debug="true"*)reg [1:0] dstate;
parameter wait2=2'd0,delay2=2'd1,count2=2'd2;
(*mark_debug="true"*)reg d_pps;
reg [31:0] cnt3;
parameter delay_lost=32'd197799999;//lost置一是在上一个head_rise（1号码元上升沿）之后的1001ms即本秒1号码元上升沿后1ms，因此在lost置一后延时989ms产生第一个d_pps上升沿
parameter cnt3_negedge=32'd99999999;
parameter cnt3_posedge=32'd199999999;//200M时钟，占空比50%;
always @(posedge clk)
begin
case(dstate)
wait2:begin
d_pps<=1'b0;
cnt3<=32'd0;
 if(lrise)//一旦lost上升沿,即B码丢失跳转到下一个状态，守时产生秒脉冲
   begin
     dstate<=delay2;
   end
end

delay2:begin
 if(cnt3==delay_lost)
   begin
     dstate<=count2;
     cnt3<=32'd0;
     d_pps<=1'b1;
   end
 else
   begin
     cnt3<=cnt3+1'd1;
     d_pps<=1'b0;
   end
end

count2:begin
if(lost)begin//B码丢失
  if(cnt3==cnt3_negedge)
    begin
      d_pps<=1'b0;
      cnt3<=cnt3+1'd1;
    end
  else if(cnt3==cnt3_posedge)
    begin
      d_pps<=1'b1;
      cnt3<=32'd0;
    end
  else
    begin
      d_pps<=d_pps;
      cnt3<=cnt3+1'd1;
    end
end

else begin//B码恢复
  dstate<=wait2;
end  
end

default:begin
d_pps<=1'b0;
cnt3<=32'd0;
dstate<=wait2;
end
  endcase
end




//case（num）,在对应的码元处提取出30位时间信息BCD码----时序逻辑
always @(posedge clk)
begin
 case(num) 
 //时间信息对应的30个码元位置(num为0时，对应为1号码元上升沿，最后binary也是存储的1号码元的脉宽信息)
 79:begin
if(binary)
  sbs[0]<=1'b1;
else
  sbs[0]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

 80:begin
if(binary)
  sbs[1]<=1'b1;
else
  sbs[1]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

 81:begin
if(binary)
  sbs[2]<=1'b1;
else
  sbs[2]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

 82:begin
if(binary)
  sbs[3]<=1'b1;
else
  sbs[3]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

 83:begin
if(binary)
  sbs[4]<=1'b1;
else
  sbs[4]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

84:begin
if(binary)
  sbs[5]<=1'b1;
else
  sbs[5]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

 85:begin
if(binary)
  sbs[6]<=1'b1;
else
  sbs[6]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end


86:begin
if(binary)
  sbs[7]<=1'b1;
else
  sbs[7]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

87:begin
if(binary)
  sbs[8]<=1'b1;
else
  sbs[8]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

89:begin
if(binary)
  sbs[9]<=1'b1;
else
  sbs[9]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

90:begin
if(binary)
  sbs[10]<=1'b1;
else
  sbs[10]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

91:begin
if(binary)
  sbs[11]<=1'b1;
else
  sbs[11]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

92:begin
if(binary)
 sbs[12]<=1'b1;
else
 sbs[12]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

93:begin
if(binary)
  sbs[13]<=1'b1;
else
  sbs[13]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

94:begin
if(binary)
  sbs[14]<=1'b1;
else
  sbs[14]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

95:begin
if(binary)
  sbs[15]<=1'b1;
else
  sbs[15]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

96:begin
if(binary)
  sbs[16]<=1'b1;
else
  sbs[16]<=1'b0;//二进制1，则5ms；二进制0，则2ms
end

//98:begin
//if(brise)
// sbs_reg<=sbs+17'd1;//pps posedge，sbs+1;
//end

default:begin
 sbs<=sbs;
end
  endcase	 
end

////case（num）,在对应的码元处提取出30位时间信息BCD码----组合逻辑---出错原因：非阻塞赋值?
//always @(*)
//begin
// case(num) 
// //时间信息对应的30个码元位置(num为0时，对应为1号码元上升沿，最后binary也是存储的1号码元的脉宽信息)
//80:begin
//if(binary)
//  sbs[0]<=1'b1;
//else
//  sbs[0]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//  81:begin
//if(binary)
//  sbs[1]<=1'b1;
//else
//  sbs[1]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

// 82:begin
//if(binary)
//  sbs[2]<=1'b1;
//else
//  sbs[2]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

// 83:begin
//if(binary)
//  sbs[3]<=1'b1;
//else
//  sbs[3]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

// 84:begin
//if(binary)
//  sbs[4]<=1'b1;
//else
//  sbs[4]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//85:begin
//if(binary)
//  sbs[5]<=1'b1;
//else
//  sbs[5]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

// 86:begin
//if(binary)
//  sbs[6]<=1'b1;
//else
//  sbs[6]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end


//87:begin
//if(binary)
//  sbs[7]<=1'b1;
//else
//  sbs[7]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//88:begin
//if(binary)
//  sbs[8]<=1'b1;
//else
//  sbs[8]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//90:begin
//if(binary)
//  sbs[9]<=1'b1;
//else
//  sbs[9]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//91:begin
//if(binary)
//  sbs[10]<=1'b1;
//else
//  sbs[10]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//92:begin
//if(binary)
//  sbs[11]<=1'b1;
//else
//  sbs[11]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//93:begin
//if(binary)
// sbs[12]<=1'b1;
//else
// sbs[12]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//94:begin
//if(binary)
//  sbs[13]<=1'b1;
//else
//  sbs[13]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//95:begin
//if(binary)
//  sbs[14]<=1'b1;
//else
//  sbs[14]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//96:begin
//if(binary)
//  sbs[15]<=1'b1;
//else
//  sbs[15]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//97:begin
//if(binary)
//  sbs[16]<=1'b1;
//else
//  sbs[16]<=1'b0;//二进制1，则5ms；二进制0，则2ms
//end

//99:begin
////num跳变到99，说明刚好上升沿
// sbs_reg<=sbs+17'd1;//pps posedge，sbs+1;
//end

//default:begin
// sbs<=sbs;
//end
//  endcase	 
//end

//检测pps上升沿
(*mark_debug="true"*)wire pps;
assign pps=lost?d_pps:b_pps;
reg pbuf,prise;
always @(posedge clk)
begin
 pbuf<=pps;
 prise<=pps&(~pbuf);
end

//模拟B码丢失
(*mark_debug="true"*)reg [7:0] lost_cnt=0;
(*mark_debug="true"*)reg lost_switch=1'b0;
always @(posedge clk)
begin
  if(prise)
    begin
     if(lost_cnt==8'd120)
          begin
            lost_cnt<=lost_cnt+1'd1;
            lost_switch<=1'b1;
          end
      else if(lost_cnt==8'd240)
          begin
            lost_cnt<=8'd0;
            lost_switch<=1'b0;
          end
      else
          begin
            lost_cnt<=lost_cnt+1'd1;
            lost_switch<=lost_switch;
          end 
    end
end




reg [1:0] sbs_state;
parameter wait3=2'd0,ini_sbs=2'd1,sbs_plus=2'd2;
//sbs秒码+1
always @(posedge clk)
begin
case(sbs_state)
wait3:begin
  if(lfall)
    begin
      sbs_state<=ini_sbs;
    end
end

ini_sbs:begin
  if(prise)
    begin
      sbs_reg<=sbs+17'd1;
      sbs_state<=sbs_plus;
    end
end

sbs_plus:begin
if(~lfall) begin
  if(prise)
    begin
      sbs_reg<=sbs_reg+17'd1;
    end
 end
else begin//每当B码恢复，都进入ini_sbs获取一次B码的sbs秒码进行对时
  sbs_state<=ini_sbs;
 end
end

default:begin
  sbs_state<=wait3;
end
  endcase
end


//(*mark_debug="true"*)reg [19:0] cnt_us;
(*mark_debug="true"*)reg [7:0] cnt1=fre-1;
//reg clk_1m;//TO AD Sampling
//parameter fre=8'd20;//fre=时钟频率/1M
always @(posedge clk)
begin
     if(prise)//对应整秒上升沿
        begin
          cnt_us<=20'd0;
          cnt1<=8'd0;//us时标与计数值全部同步清零
          clk_1m<=1'b1;
        end
        
     else if(cnt1==(fre-1))//cnt_us+1,clk_1M置1
        begin
           if(cnt_us==20'd999999)
             begin
               cnt1<=cnt1;
               cnt_us<=cnt_us;//当时标=1M-1时,不依靠cnt1计数来将时标清零,只依靠整秒上升沿来同步清零（保证时标范围为0~1M-1）
               clk_1m<=clk_1m;
             end
           else
             begin
               cnt1<=8'd0;
               cnt_us<=cnt_us+20'd1;
               clk_1m<=1'b1;
             end
        end    
     
     else if(cnt1==(fre/2-1))//cnt_us+1,clk_1M置0
        begin
          cnt1<=cnt1+8'd1;
          clk_1m<=1'b0;
        end
        
     else
        begin
           cnt1<=cnt1+8'd1;
           cnt_us<=cnt_us;
           clk_1m<=clk_1m;
        end
   end



endmodule

