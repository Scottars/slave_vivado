`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/20 14:56:24
// Design Name: 
// Module Name: ltc2290
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
module ltc2290(
input clk,    //125M时钟
input ad_clk,//A、B通道共用一个时钟1MHz/us产生
input [11:0] da,
input [11:0] db,//AD数据
output reg[31:0] cha_data,
output reg[31:0] chb_data,
output reg store_en
    );

reg [15:0] fixed_rega;
reg [15:0] fixed_regb;
wire  [31:0] float_rega; 
wire [31:0] float_regb;
wire [31:0] cha_V;
wire [31:0] chb_V;


//100101001，补码表示
//浮点数转换耗时6clk
fixed_to_float u1 (
   .s_axis_a_tdata(fixed_rega), // input [11 : 0] a
  .s_axis_a_tvalid(1'b1),
  .aclk(clk), // input clk
  .m_axis_result_tdata(float_rega) // output [31 : 0] result
);
fixed_to_float u2 (
   .s_axis_a_tdata(fixed_regb), // input [11 : 0] a
.s_axis_a_tvalid(1'b1),
.aclk(clk), // input clk
.m_axis_result_tdata(float_regb) // output [31 : 0] result
);


multiply u3 (
.s_axis_a_tdata(float_rega), // input [31 : 0] a
  .s_axis_b_tdata(32'h3B1DF100), // the value 39FFF400 is actuuall  0.0004882 ps:如果对应到输入电压的范围，我我们就还需要?5 0.0004882*5=0.00241 which is 3B1DF100
  .aclk(clk), // input clk
  .m_axis_result_tdata(cha_V) //mV电压值 
);



multiply u4 (
.s_axis_a_tdata(float_regb), // input [31 : 0] a
  .s_axis_b_tdata(32'h3B1DF100), // input [31 : 0] b:2.44mV分辨率
  .aclk(clk), // input clk
  .m_axis_result_tdata(chb_V) //mV电压值 
);


//检测AD采样时钟上升沿
reg ad_clk_buf,ad_clk_rise;
always @(posedge clk)
begin
  ad_clk_buf<=ad_clk;
  ad_clk_rise<=ad_clk&(~ad_clk_buf); //实际上要延时了一个周期clock了,
end


parameter idle=3'b000,wait1=3'b001,read=3'b010,wait2=3'b011,wait3=3'b100;
(*mark_debug= "true"*)reg [2:0] state=idle;
reg [4:0] i=0; //延时使用

//AD采样数据读取、转换与存储-状态机:耗时27clk per data
always @(posedge clk)
begin
case(state)
//等待采样时钟上升沿
 idle:begin
 store_en<=1'b0; //存储使能为0
 i<=0; 
 if(ad_clk_rise) //ad的clock 的上升沿是否到达
	     state<=wait1;
  end
  //采样时钟上升沿到采样数据更新的延时：数据手册最大5.4ns，在这儿取4clk=32ns,一个125M的时钟，其周期是8ns
 wait1:begin     
     if(i==3)
	     begin
	       state<=read;
			 i<=0;
		  end
	  else 
	       i<=i+1;
  end
//原始12bit采样数据（补码表示）送入浮点数转换ip核
 read:begin
    fixed_rega<={4'b0000,da-12'h800};
	 fixed_regb<={4'b0000,db-12'h800};
	 state<=wait2;
 end
//浮点数转换延时：6clk+浮点数乘法延时8clk=14clk
wait2:begin
   if(i==20)//多几个clk的延时
	   begin
		  state<=wait3;
		  cha_data<=cha_V;
		  chb_data<=chb_V;//cha_data与chb_data缓存mV值，送入存储模块
		  store_en<=1'b1;//存储使能置1
		  i<=0;
		end
	else
	     i<=i+1; 
end

//store_en置一5个clk，以保证下级存储模块可检测到
wait3:begin
  if(i==4)
    state<=idle;
  else
    i<=i+1;
end



default:begin
 state<=idle;
end
endcase
end
//////这个always块 就是用来更新写数据的地址，然后将带有时标的数据存储进去
//always@()


////assign ad1_data =clk_5M;



endmodule
