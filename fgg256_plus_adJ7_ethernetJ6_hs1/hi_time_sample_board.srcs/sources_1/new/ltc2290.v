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
input clk,    //125Mʱ��
input ad_clk,//A��Bͨ������һ��ʱ��1MHz/us����
input [11:0] da,
input [11:0] db,//AD����
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


//100101001�������ʾ
//������ת����ʱ6clk
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
  .s_axis_b_tdata(32'h3B1DF100), // the value 39FFF400 is actuuall  0.0004882 ps:�����Ӧ�������ѹ�ķ�Χ�������Ǿͻ���Ҫ?5 0.0004882*5=0.00241 which is 3B1DF100
  .aclk(clk), // input clk
  .m_axis_result_tdata(cha_V) //mV��ѹֵ 
);



multiply u4 (
.s_axis_a_tdata(float_regb), // input [31 : 0] a
  .s_axis_b_tdata(32'h3B1DF100), // input [31 : 0] b:2.44mV�ֱ���
  .aclk(clk), // input clk
  .m_axis_result_tdata(chb_V) //mV��ѹֵ 
);


//���AD����ʱ��������
reg ad_clk_buf,ad_clk_rise;
always @(posedge clk)
begin
  ad_clk_buf<=ad_clk;
  ad_clk_rise<=ad_clk&(~ad_clk_buf); //ʵ����Ҫ��ʱ��һ������clock��,
end


parameter idle=3'b000,wait1=3'b001,read=3'b010,wait2=3'b011,wait3=3'b100;
(*mark_debug= "true"*)reg [2:0] state=idle;
reg [4:0] i=0; //��ʱʹ��

//AD�������ݶ�ȡ��ת����洢-״̬��:��ʱ27clk per data
always @(posedge clk)
begin
case(state)
//�ȴ�����ʱ��������
 idle:begin
 store_en<=1'b0; //�洢ʹ��Ϊ0
 i<=0; 
 if(ad_clk_rise) //ad��clock ���������Ƿ񵽴�
	     state<=wait1;
  end
  //����ʱ�������ص��������ݸ��µ���ʱ�������ֲ����5.4ns�������ȡ4clk=32ns,һ��125M��ʱ�ӣ���������8ns
 wait1:begin     
     if(i==3)
	     begin
	       state<=read;
			 i<=0;
		  end
	  else 
	       i<=i+1;
  end
//ԭʼ12bit�������ݣ������ʾ�����븡����ת��ip��
 read:begin
    fixed_rega<={4'b0000,da-12'h800};
	 fixed_regb<={4'b0000,db-12'h800};
	 state<=wait2;
 end
//������ת����ʱ��6clk+�������˷���ʱ8clk=14clk
wait2:begin
   if(i==20)//�༸��clk����ʱ
	   begin
		  state<=wait3;
		  cha_data<=cha_V;
		  chb_data<=chb_V;//cha_data��chb_data����mVֵ������洢ģ��
		  store_en<=1'b1;//�洢ʹ����1
		  i<=0;
		end
	else
	     i<=i+1; 
end

//store_en��һ5��clk���Ա�֤�¼��洢ģ��ɼ�⵽
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
//////���always�� ������������д���ݵĵ�ַ��Ȼ�󽫴���ʱ������ݴ洢��ȥ
//always@()


////assign ad1_data =clk_5M;



endmodule
