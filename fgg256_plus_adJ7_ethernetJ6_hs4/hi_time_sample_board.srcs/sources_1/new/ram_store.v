module ram_store(
input clk,//��125M��̫��ʱ��/���¾���Ƶʱ��
input [31:0] cha_data,
input [31:0] chb_data,//AD���ݣ���������ʾ��ʵ�ʵ�ѹֵ
input [31:0] cnt_us,
input [31:0] sbs,
input store_en,//�洢ʹ��
//input [8:0]rd_addr,
//��������̫������ģ��
input seq_1,
input [9:0] eth_rd_addr,
output [31:0] eth_rd_data,//ram���
output reg ram_rdy
//output reg ram_rdy1,
//output reg ram_rdy2
);


reg wr_en=0;
//���addr �Լ��л��ͼ���
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

///////////˫ ram�л�����////////////////



wire [9:0] eth_rd_addr1;
wire [31:0] eth_rd_data1;
wire [9:0] eth_rd_addr2;
wire [31:0] eth_rd_data2;
// ����ram_switch_signal���л�������ÿ�����100�δ洢������л���
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
// ����״̬�� �洢a  �洢b

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
           
//		   reg_us<=32'd0;//���Ͽ�ʼ��һ�ַ��ͣ������usʱ��Ӧ���ȹ��㣬��Ȼ�������У���һ�����us=1M-1,���ֵ�һ��us=0���ͻ�����Ϊ���룩
//        end
//        else begin
//           cnt<=cnt+1'b1;
//        end
    end
       
end

pre_judge:begin
 if(ts_flag)//�Ѽ�������
     state<=write_cha;//����us�жϣ���Ϊһ�������ﲻ����2�ο��룩
 else
     state<=us_judge;
end

//�жϱ���usֵ���ϴ�usֵ��������us<�ϴ�us��˵�����루��Ϊ�����������ģ�������������ֵ֮����С��1s�����Կ����us�϶�С����һ��us��
us_judge:begin
  reg_us<=cnt_us;//reg_us���ڻ�����һ�δ洢��usֵ
  if(cnt_us<reg_us)//����us<�ϴ�us���������ǿ�������  SCottar�� ʵ���ϣ�����cnt_us ���ԣ��䷶Χ����0-1 000 000 -1  ��99999
//  if(cnt_us ==0) 
    begin
        ts_cnt<=(cha_addr>>1) - 1;//�������ݸ���ts_cnt�͵��ڵ�ǰ�Ѵ洢���ݸ���cnt
//        ts_cnt<=cnt-1;//�������ݸ���ts_cnt�͵��ڵ�ǰ�Ѵ洢���ݸ���cnt
		ts_flag<=1'b1;//�Ѽ�������ָʾ��ts=this second
		state<=write_cha;
	 end
   else begin 
      ts_cnt <= 8'd100;
      ts_flag<=1'b0;//δ��������
      state<=write_cha;
    end
      
       
end



///������ݴ����źţ����������򽫸���������Ϣ
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
//�ȼ���ʱ�ӣ������λ���仯����̫�������ܹ���⵽
en_eth:begin
    if(i==4) begin
        i<=0;
        ram_rdy=0;
        ts_flag<=0;//����ָʾ����
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
