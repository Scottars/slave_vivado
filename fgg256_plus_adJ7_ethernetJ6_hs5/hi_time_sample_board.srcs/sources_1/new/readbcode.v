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
//(*mark_debug="true"*)input bcode;//����B��
(*mark_debug="true"*)input bcode0;//����B��
input rst_n;//��λ
(*mark_debug="true"*)output reg [16:0] sbs_reg;//17λsbs��
(*mark_debug="true"*)output reg [19:0] cnt_us=20'd999999;
(*mark_debug="true"*)output reg clk_1m;
output reg user_led_green;



(*mark_debug="true"*)reg [31:0] cnt,width1,width2;//width1Ϊǰһ����Ԫ������width2Ϊ��ǰ��Ԫ����,��Ϊ��15~25��Ϊ2ms,45~55��Ϊ5ms,75~85��Ϊ8ms
reg bbuf,brise;//�����ؼ��
reg bbuf1,bfall;//�½��ؼ��
reg state;//case�е�״̬
reg [6:0] num;//��Ԫ����ֵ��0~99
reg [4:0] i;//time_bcd[i]��ֵ��0~29
reg binary;//��ʾ������1/0
reg head;//B���ײ�Pr��Ԫָʾ
(*mark_debug="true"*)reg [16:0] sbs;

parameter fre=8'd200;//fre=ʱ��Ƶ��/1M---����fre��Ӧʱ��Ϊ1us
parameter c2ms_low=32'd350000;
parameter c2ms_high=32'd450000;//����2ms���ۼ���ֵΪ200*2000=400000
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
//��ʧģ��
reg bcode,bcode1;
//assign bcode=lost_switch?0:bcode0;
//assign bcode=bcode0;

always @(posedge clk)
begin
bcode1<=bcode0;
bcode<=bcode1;
end

//���B������������
always @(posedge clk)
begin
 bbuf<=bcode;
 brise<=bcode&(~bbuf);
end




//���B�������½���
always @(posedge clk)
begin
 bbuf1<=bcode;
 bfall<=(~bcode)&bbuf1;
end

//�������
always @(posedge clk)
begin
  if(!rst_n)//��λ�źţ��͵�ƽ��Ч
     begin
	    cnt<=0;	
		 width1<=0;
		 width2<=0;
	  end
  else begin
    if(bcode)//�ߵ�ƽʱ�������������
       cnt<=cnt+1;
    else if(bfall)//�½���ʱ�������㣬׼��������һ�μ�����ͬʱ��������������и�ֵ
	    begin
		 width1<=width2;//����һ����Ԫ����ֵ����width1
		 width2<=cnt;//����ǰֵ����width2
		 cnt<=0;//��������
		 end
  end
end


//state 0��1��������--������ת�����ٽ�����Ԫ����(����case���ֻ��Ϊ�˷��㽨��һ���Ⱥ�˳��)
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
1'b0:begin//��ÿ��B�������ؽ�������--�������Լ�֡ͷ�ж�
  if(brise)
    begin
     if((width2>c8ms_low)&&(width1>c8ms_low))//������������Ϊ8ms
		  head<=1'b1;//֡ͷPr
	  else if((width2>c5ms_low)&&(width2<c5ms_high))//����Ϊ5ms����Ӧ������1,binary��1
	     begin
		  binary<=1'b1;
		  	  head<=1'b0;	
		  end
		else if((width2>c2ms_low)&&(width2<c2ms_high))//����Ϊ2ms����Ӧ������0��binary��0
		   begin
		     binary<=1'b0;
		  	  head<=1'b0;	
		   end
		 else
		  head<=1'b0;	
	state<=1'b1;//������һ��
	 end
  else
    state<=1'b0;
	end


1'b1:begin//��Ԫ����
	if(head)//��⵽֡ͷ�󣬴�ʱΪ1����Ԫ�������أ�width2ΪPr����������Ԫ����ֵ��0
	    num<=0;
	  else 
	     begin
	    num<=num+1;
		  end
   state<=0;//�ص�״̬0		
	end
endcase	
 end
end

//B�붪ʧ�ж�
//head�������ж�
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


//head�����غ���ʱ����һ���жϴ�:���ڸô���δ����B�������أ�����ΪB�붪ʧ
reg [31:0] jcnt;
(*mark_debug="true"*)reg lost;
reg [1:0] jstate;
parameter idle=2'd0,count=2'd1,jstart=2'd2;
parameter jlow=32'd199800000;
parameter jhigh=32'd200200000;//�жϴ�λ��:��ʱ999ms~1001ms

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
  if(head_rise)//1����Ԫ������
     begin
       jstate<=count;
       lost<=1'b0;
       jcnt<=32'd0;
     end
end 
//��ʱ����
count:begin
     jcnt<=jcnt+1'd1;
     if(jcnt==jlow)
       jstate<=jstart;
end
//�жϴ���ʼ
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
     lost<=1'b1;//��ʧָʾ
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

//B��δ��ʧʱ,ͨ��B��Pr��ʼ��־��ʱ����������
(*mark_debug="true"*)reg b_pps;
reg [31:0] cnt2=0;
reg state_bpps;
parameter wait1=1'b0,delay1=1'b1;//waitΪverilog��keyword
parameter cnt2_negegde=32'd100000000;//�ڸü���ֵ�����������½���,�ɵ����ü���ֵ�Ե���������ռ�ձ�
parameter cnt2_posedge=32'd197999999;//��head_rise��1����Ԫ�����غ���ʱ990ms����������������
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

//lost=0ʱ,��b_pps�����ϣ�ͨ�����������ʱ������������d_pps����B��lost����d_pps�����Ͻ�����ʱ
//��⵽lost��������lost���Ļ���ͨ����ʱ������һ��d_pps,֮��ͨ������1s��������һϵ�е�������d_pps

//���lost�����ء��½��أ�ָʾB�붪ʧ���ָ�
reg lbuf=1,lrise,lfall;
always @(posedge clk)
begin
 lbuf<=lost;
 lrise<=lost&(~lbuf);
 lfall<=(~lost)&lbuf;
end

//��ʱ�����ؾ���ѭ����������������
(*mark_debug="true"*)reg [1:0] dstate;
parameter wait2=2'd0,delay2=2'd1,count2=2'd2;
(*mark_debug="true"*)reg d_pps;
reg [31:0] cnt3;
parameter delay_lost=32'd197799999;//lost��һ������һ��head_rise��1����Ԫ�����أ�֮���1001ms������1����Ԫ�����غ�1ms�������lost��һ����ʱ989ms������һ��d_pps������
parameter cnt3_negedge=32'd99999999;
parameter cnt3_posedge=32'd199999999;//200Mʱ�ӣ�ռ�ձ�50%;
always @(posedge clk)
begin
case(dstate)
wait2:begin
d_pps<=1'b0;
cnt3<=32'd0;
 if(lrise)//һ��lost������,��B�붪ʧ��ת����һ��״̬����ʱ����������
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
if(lost)begin//B�붪ʧ
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

else begin//B��ָ�
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




//case��num��,�ڶ�Ӧ����Ԫ����ȡ��30λʱ����ϢBCD��----ʱ���߼�
always @(posedge clk)
begin
 case(num) 
 //ʱ����Ϣ��Ӧ��30����Ԫλ��(numΪ0ʱ����ӦΪ1����Ԫ�����أ����binaryҲ�Ǵ洢��1����Ԫ��������Ϣ)
 79:begin
if(binary)
  sbs[0]<=1'b1;
else
  sbs[0]<=1'b0;//������1����5ms��������0����2ms
end

 80:begin
if(binary)
  sbs[1]<=1'b1;
else
  sbs[1]<=1'b0;//������1����5ms��������0����2ms
end

 81:begin
if(binary)
  sbs[2]<=1'b1;
else
  sbs[2]<=1'b0;//������1����5ms��������0����2ms
end

 82:begin
if(binary)
  sbs[3]<=1'b1;
else
  sbs[3]<=1'b0;//������1����5ms��������0����2ms
end

 83:begin
if(binary)
  sbs[4]<=1'b1;
else
  sbs[4]<=1'b0;//������1����5ms��������0����2ms
end

84:begin
if(binary)
  sbs[5]<=1'b1;
else
  sbs[5]<=1'b0;//������1����5ms��������0����2ms
end

 85:begin
if(binary)
  sbs[6]<=1'b1;
else
  sbs[6]<=1'b0;//������1����5ms��������0����2ms
end


86:begin
if(binary)
  sbs[7]<=1'b1;
else
  sbs[7]<=1'b0;//������1����5ms��������0����2ms
end

87:begin
if(binary)
  sbs[8]<=1'b1;
else
  sbs[8]<=1'b0;//������1����5ms��������0����2ms
end

89:begin
if(binary)
  sbs[9]<=1'b1;
else
  sbs[9]<=1'b0;//������1����5ms��������0����2ms
end

90:begin
if(binary)
  sbs[10]<=1'b1;
else
  sbs[10]<=1'b0;//������1����5ms��������0����2ms
end

91:begin
if(binary)
  sbs[11]<=1'b1;
else
  sbs[11]<=1'b0;//������1����5ms��������0����2ms
end

92:begin
if(binary)
 sbs[12]<=1'b1;
else
 sbs[12]<=1'b0;//������1����5ms��������0����2ms
end

93:begin
if(binary)
  sbs[13]<=1'b1;
else
  sbs[13]<=1'b0;//������1����5ms��������0����2ms
end

94:begin
if(binary)
  sbs[14]<=1'b1;
else
  sbs[14]<=1'b0;//������1����5ms��������0����2ms
end

95:begin
if(binary)
  sbs[15]<=1'b1;
else
  sbs[15]<=1'b0;//������1����5ms��������0����2ms
end

96:begin
if(binary)
  sbs[16]<=1'b1;
else
  sbs[16]<=1'b0;//������1����5ms��������0����2ms
end

//98:begin
//if(brise)
// sbs_reg<=sbs+17'd1;//pps posedge��sbs+1;
//end

default:begin
 sbs<=sbs;
end
  endcase	 
end

////case��num��,�ڶ�Ӧ����Ԫ����ȡ��30λʱ����ϢBCD��----����߼�---����ԭ�򣺷�������ֵ?
//always @(*)
//begin
// case(num) 
// //ʱ����Ϣ��Ӧ��30����Ԫλ��(numΪ0ʱ����ӦΪ1����Ԫ�����أ����binaryҲ�Ǵ洢��1����Ԫ��������Ϣ)
//80:begin
//if(binary)
//  sbs[0]<=1'b1;
//else
//  sbs[0]<=1'b0;//������1����5ms��������0����2ms
//end

//  81:begin
//if(binary)
//  sbs[1]<=1'b1;
//else
//  sbs[1]<=1'b0;//������1����5ms��������0����2ms
//end

// 82:begin
//if(binary)
//  sbs[2]<=1'b1;
//else
//  sbs[2]<=1'b0;//������1����5ms��������0����2ms
//end

// 83:begin
//if(binary)
//  sbs[3]<=1'b1;
//else
//  sbs[3]<=1'b0;//������1����5ms��������0����2ms
//end

// 84:begin
//if(binary)
//  sbs[4]<=1'b1;
//else
//  sbs[4]<=1'b0;//������1����5ms��������0����2ms
//end

//85:begin
//if(binary)
//  sbs[5]<=1'b1;
//else
//  sbs[5]<=1'b0;//������1����5ms��������0����2ms
//end

// 86:begin
//if(binary)
//  sbs[6]<=1'b1;
//else
//  sbs[6]<=1'b0;//������1����5ms��������0����2ms
//end


//87:begin
//if(binary)
//  sbs[7]<=1'b1;
//else
//  sbs[7]<=1'b0;//������1����5ms��������0����2ms
//end

//88:begin
//if(binary)
//  sbs[8]<=1'b1;
//else
//  sbs[8]<=1'b0;//������1����5ms��������0����2ms
//end

//90:begin
//if(binary)
//  sbs[9]<=1'b1;
//else
//  sbs[9]<=1'b0;//������1����5ms��������0����2ms
//end

//91:begin
//if(binary)
//  sbs[10]<=1'b1;
//else
//  sbs[10]<=1'b0;//������1����5ms��������0����2ms
//end

//92:begin
//if(binary)
//  sbs[11]<=1'b1;
//else
//  sbs[11]<=1'b0;//������1����5ms��������0����2ms
//end

//93:begin
//if(binary)
// sbs[12]<=1'b1;
//else
// sbs[12]<=1'b0;//������1����5ms��������0����2ms
//end

//94:begin
//if(binary)
//  sbs[13]<=1'b1;
//else
//  sbs[13]<=1'b0;//������1����5ms��������0����2ms
//end

//95:begin
//if(binary)
//  sbs[14]<=1'b1;
//else
//  sbs[14]<=1'b0;//������1����5ms��������0����2ms
//end

//96:begin
//if(binary)
//  sbs[15]<=1'b1;
//else
//  sbs[15]<=1'b0;//������1����5ms��������0����2ms
//end

//97:begin
//if(binary)
//  sbs[16]<=1'b1;
//else
//  sbs[16]<=1'b0;//������1����5ms��������0����2ms
//end

//99:begin
////num���䵽99��˵���պ�������
// sbs_reg<=sbs+17'd1;//pps posedge��sbs+1;
//end

//default:begin
// sbs<=sbs;
//end
//  endcase	 
//end

//���pps������
(*mark_debug="true"*)wire pps;
assign pps=lost?d_pps:b_pps;
reg pbuf,prise;
always @(posedge clk)
begin
 pbuf<=pps;
 prise<=pps&(~pbuf);
end

//ģ��B�붪ʧ
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
//sbs����+1
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
else begin//ÿ��B��ָ���������ini_sbs��ȡһ��B���sbs������ж�ʱ
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
//parameter fre=8'd20;//fre=ʱ��Ƶ��/1M
always @(posedge clk)
begin
     if(prise)//��Ӧ����������
        begin
          cnt_us<=20'd0;
          cnt1<=8'd0;//usʱ�������ֵȫ��ͬ������
          clk_1m<=1'b1;
        end
        
     else if(cnt1==(fre-1))//cnt_us+1,clk_1M��1
        begin
           if(cnt_us==20'd999999)
             begin
               cnt1<=cnt1;
               cnt_us<=cnt_us;//��ʱ��=1M-1ʱ,������cnt1��������ʱ������,ֻ����������������ͬ�����㣨��֤ʱ�귶ΧΪ0~1M-1��
               clk_1m<=clk_1m;
             end
           else
             begin
               cnt1<=8'd0;
               cnt_us<=cnt_us+20'd1;
               clk_1m<=1'b1;
             end
        end    
     
     else if(cnt1==(fre/2-1))//cnt_us+1,clk_1M��0
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

