`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ethernet_test
// �������˳�������ǧ����̫��udpͨ�Ų��ԣ�ǧ����̫��ͨ��ʱ��FPGA��RTL8211֮��ͨ�Žӿ�ΪGMII
//      �˳������ð�����̫������ͨ�ţ�������̫��MII�ӿ�udpͨ�ŵĳ���ο�ethernet_100
//////////////////////////////////////////////////////////////////////////////////
module ethernet_test(
				
                  input sys_clk_50M,
                  
                  input ext_bcode,
         
//					output  fpga_clk,     // �˽�pfpaclk �������Ǹ����               
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
                   output e_mdc,                      //MDIO��ʱ���źţ����ڶ�дPHY�ļĴ���
				   inout  e_mdio,                     //MDIO�������źţ����ڶ�дPHY�ļĴ���
		
            
					input	 e_rxc,                      //125Mhz ethernet gmii rx clock  phy ��mac�� ����125M��ϵͳʱ�ӣ�����ʱ�ӡ�
					input	 e_rxdv,	                    //GMII ����������Ч�ź�    phy��mac
					input	 e_rxer,	                    //GMII �������ݴ����ź�				  phy ��mac	
					input  [7:0] e_rxd,                //GMII ��������	          phy��mac

					input	 e_txc,                      //25Mhz ethernet mii tx clock   phyоƬ���͵�mac        
					output e_gtxc,                     //25Mhz ethernet gmii tx clock   mac�ṩgtxc
					output e_txen,                     //GMII ����������Ч�ź�	      mac ���͵�phy
					//output e_txer,                     //GMII �������ݴ����ź�		 mac �㷢�͵�phy
					output [7:0] e_txd	              //GMII ��������      mac ��phy
  
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

// ��ʾϵͳ��������ָʾ��
reg [31:0]timer_led;
initial begin
timer_led <=0;
end
always @(posedge sys_clk)
begin
    if(timer_led == 32'd200_000_000)
        begin
            user_led_board <=1'b0;
            user_led_yellow <=1'b0 || ~seq_1; // ���ʱ����������ʱ��
                                                   // ���ڽ������ݵķ��ͣ� ����������ǵ͵�ƽ���й⡣
                                                 //����seq_1��ʱ�򣬴�ʱ��������Ϊ�͵�ƽ����ʱ��Ӧ��һֱ����ߵ�ƽ��ʹ�õƹ�һֱ������
                                                 //����seq_1��ʱ�򣬴�ʱ������Ϊ�ߵ�ƽ����ʱ��Ӧ������ߵ͵�ƽ�Ľ�����ʹ�õƹ��ܵ�user_led_yellow �Ŀ���
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

//assign ram_rdy= ram_rdy & seq_1; // ��������̫�������ݷ��ͣ��伴�ǵ��й��ʱ
//assign user_led_yellow  = seq_1;




wire rst;
assign rst=1'b1;
//input ext_bcode;
wire [16:0] sbs;
wire [19:0] cnt_us;
wire clk_1m;
readbcode u3(
.clk(sys_clk), 
.rst_n(rst),//��λ�ź�
.bcode0(ext_bcode),//�ⲿB������
.sbs_reg(sbs),
.cnt_us(cnt_us),
.clk_1m(clk_1m),//��B��õ���17λ����
.user_led_green(user_led_green)
);

///b code simulationm 
//���һ��cnt_us ���һ�� sbs
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
wire [15:0] rx_total_length;          //rx ��IP���ĳ���
wire [15:0] tx_total_length;          //tx ��IP���ĳ���
wire [15:0] rx_data_length;           //rx ��UDP�����ݰ�����
wire [15:0] tx_data_length;           //rx ��UDP�����ݰ�����

wire data_receive;
reg ram_wr_finish;

reg [31:0] udp_data [4:0];                        //�洢�����ַ�
reg ram_wren_i;
reg [9:0] ram_addr_i;
reg [31:0] ram_data_i;
reg [9:0] i;

wire data_o_valid;
wire wea;
wire [9:0] addra;
wire [31:0] dina;
//˵������ǰ������data o valid �Ļ�����ʱ�� wr finsh ��Ч�� ���ܿ�ʼдram  
//assign wea=ram_wr_finish?data_o_valid:ram_wren_i;          //ram дʹ���ź�ѡ��  
//assign addra=ram_wr_finish?ram_wr_addr:ram_addr_i;         //ram д��ַѡ��gi
//assign dina=ram_wr_finish?ram_wr_data:ram_data_i;          //ram д����ѡ��  

//assign wea=ram_wren_i;          //ram дʹ���ź�ѡ��  
assign wea=1;          //ram дʹ���ź�ѡ��  
assign addra=ram_addr_i;         //ram д��ַѡ��gi
assign dina=ram_data_i;          //ram д����ѡ��  


assign tx_data_length=16'd816;  //��---------------------------- ------------- udp2+2  + 2 +2   +data��2+1+1+4+400+400�� + fcs   
assign tx_total_length=16'd836;//����ط���������̫������̫�� 6+6+2    ip20
(*mark_debug ="true"*)wire ram_rdy;
(*mark_debug ="true"*)reg ram_rdy1=1'b0;
(*mark_debug ="true"*)reg ram_rdy2=1'b0;
(*mark_debug ="true"*)wire [9:0] ram_rd_addr;
(*mark_debug ="true"*)wire [31:0]ram_rd_data;
////////udp���ͺͽ��ճ���/////////////////// 
udp u1(
	.reset_n(reset_n),
	.e_rxc(e_rxc),
	.e_rxd(e_rxd),
   .e_rxdv(e_rxdv),
	.e_txen(e_txen),
	.e_txd(e_txd),
	.e_txer(e_txer),		
	
	.data_o_valid(data_o_valid),                    //���ݽ�����Ч�ź�,д��RAM/
	.ram_wr_data(ram_wr_data),                      //���յ���32bit����д��RAM/	
	.rx_total_length(rx_total_length),              //����IP�����ܳ���/
	.rx_state(rx_state),                            //for chipscope test
	.rx_data_length(rx_data_length),                //����IP�������ݳ���/	
	.ram_wr_addr(ram_wr_addr),                      //ramд���ݵ�ַ
	.data_receive(data_receive),                    //���յ���̫�����ݰ���־
	
	.rdy1(ram_rdy1),
    .rdy2(ram_rdy2),
	.ram_rd_data(ram_rd_data),                      //RAM������32bit����/
	.tx_state(tx_state),                            //for chipscope test

	.tx_data_length(tx_data_length),                //����IP�������ݳ���/	
	.tx_total_length(tx_total_length),              //�ӷ���IP�����ܳ���/
	.ram_rd_addr(ram_rd_addr)                       //ram�����ݵ�ַ

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
.clk(e_rxc),    //125Mʱ��
.ad_clk(ad1_clk),//A��Bͨ������һ��ʱ��1MHz/us����
.da(ad1_data),
.db(ad2_data),//AD����
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
.store_en(store_en), // ltc2290 ģ�鴫���ram�洢����
.eth_rd_addr(ram_rd_addr),
.eth_rd_data(ram_rd_data),
.seq_1(seq_1),
.ram_rdy(ram_rdy)
);   


///// ���ַ��� ֻ��Ҫ�ϸ�������ʱ��ʱ�䣬���������ĶԽӽӿ�

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


//�ϴ��ٶ��趨�Լ����㷽��
//�趨�����ٶ�
//ad �Ĳ����ٶ�1M�������ۼ�100���������ݵķ���


always@(posedge e_rxc)
begin
case(ram_state)
ram_state_idle:begin
    if(ram_rdy == 1)
        ram_state <= ram_state_rdy1;
    else
        ram_state <=ram_state_idle;
end
ram_state_rdy1:begin // ����ǵȴ���̫���ٴν���idle 
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
