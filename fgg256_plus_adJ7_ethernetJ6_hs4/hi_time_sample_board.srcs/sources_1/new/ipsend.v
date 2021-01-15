`timescale 1ns / 1ps
/****************************************/
//      GMII UDP数据包发送模块　　　　　　　//
/****************************************/

module ipsend(
				  input              clk,                   //GMII发送的时钟信号
				  output reg         txen,                  //GMII数据使能信号
				  output reg         txer,                  //GMII发送错误信号
				  output reg [7:0]   dataout,               //GMII发送数据
				  input      [31:0]  crc,                   //CRC32校验码
				  input      [31:0]  datain,                //RAM中的数据	 
				  output reg         crcen,                 //CRC32 校验使能
				  output reg         crcre,                 //CRC32 校验清除

				  (*mark_debug ="true"*)output reg [3:0]   tx_state,              //发送状态机    
				  input      [15:0]  tx_data_length,        //发送的数据包的长度
				  input      [15:0]  tx_total_length,       //发送包的长度
				  output reg [9:0]   ram_rd_addr ,           //ram读地址,
				  
				  input rdy1,
				  input rdy2
				  
	  );

reg [31:0]  datain_reg;

reg [31:0] ip_header [6:0];                  //数据段为1K

reg [7:0] preamble [7:0];                    //preamble
reg [7:0] mac_addr [13:0];                   //mac address
reg [4:0] i,j;

reg [31:0] check_buffer;
reg [31:0] time_counter;
reg [15:0] tx_data_counter;

parameter idle=4'b0000,start=4'b0001,make=4'b0010,send55=4'b0011,sendmac=4'b0100,sendheader=4'b0101,
          senddata=4'b0110,sendcrc=4'b0111;



initial
  begin
	 tx_state<=idle;
	 //定义IP 包头
	 preamble[0]<=8'h55;                 //7个前导码55,一个帧开始符d5
	 preamble[1]<=8'h55;
	 preamble[2]<=8'h55;
	 preamble[3]<=8'h55;
	 preamble[4]<=8'h55;
	 preamble[5]<=8'h55;
	 preamble[6]<=8'h55;
	 preamble[7]<=8'hD5;
	 
//	 mac_addr[0]<=8'h00;                 //目的MAC地址 ff-ff-ff-ff-ff-ff, 全ff为广播包, asua 的maac地址：38-D5-47-4A-7D-0A
//	 mac_addr[1]<=8'h00;
//	 mac_addr[2]<=8'h00;
//	 mac_addr[3]<=8'h00;
//	 mac_addr[4]<=8'h00;
//	 mac_addr[5]<=8'h00;
	 
	 
//	 mac_addr[0]<=8'h38;                 //目的MAC地址 ff-ff-ff-ff-ff-ff, 全ff为广播包, asua 的maac地址：38-D5-47-4A-7D-0A
//	 mac_addr[1]<=8'hD5;
//	 mac_addr[2]<=8'h47;
//	 mac_addr[3]<=8'h4A;
//	 mac_addr[4]<=8'h7D;
//	 mac_addr[5]<=8'h0A;
	 
 

	 
//	  mac_addr[0]<=8'h00;                 //服务器虚拟的192.168.100.64的ip 的maac地址：00-50-56-88-B4-3f  hs1
//	 mac_addr[1]<=8'h50;
//	 mac_addr[2]<=8'h56;
//	 mac_addr[3]<=8'h88;
//	 mac_addr[4]<=8'hB4;
//	 mac_addr[5]<=8'h3F;
	 
//	  mac_addr[0]<=8'h00;                 //服务器虚拟的192.168.100.65的ip 的maac地址：00-50-56-88-31-AF  hs2
//	 mac_addr[1]<=8'h50;
//	 mac_addr[2]<=8'h56;
//	 mac_addr[3]<=8'h88;
//	 mac_addr[4]<=8'h31;
//	 mac_addr[5]<=8'hAF;
	 
//	  mac_addr[0]<=8'h00;                 //服务器虚拟的192.168.100.66的ip 的maac地址：00-50-56-88-54-B7  hs3
//	 mac_addr[1]<=8'h50;
//	 mac_addr[2]<=8'h56;
//	 mac_addr[3]<=8'h88;
//	 mac_addr[4]<=8'h54;
//	 mac_addr[5]<=8'hB7;
	 
	  mac_addr[0]<=8'h00;                 //服务器虚拟的192.168.100.67的ip 的maac地址：00-50-56-88-6D-AD   hs4
	 mac_addr[1]<=8'h50;
	 mac_addr[2]<=8'h56;
	 mac_addr[3]<=8'h88; 
	 mac_addr[4]<=8'h6D;
	 mac_addr[5]<=8'hAD;
	 
	 //	 mac_addr[0]<=8'h00;                 //服务器虚拟的192.168.100.63的ip 的mac地址：00-50-56-88-51-59  hs5
//	 mac_addr[1]<=8'h50;
//	 mac_addr[2]<=8'h56;
//	 mac_addr[3]<=8'h88;
//	 mac_addr[4]<=8'h51;
//	 mac_addr[5]<=8'h59;
	 
	
	 
	 mac_addr[6]<=8'h00;                 //默认的开发板源MAC地址 00-0A-35-01-FE-C0, 用户也可以修改
	 mac_addr[7]<=8'h0A;
	 mac_addr[8]<=8'h35;
	 mac_addr[9]<=8'h01;
	 mac_addr[10]<=8'hFE;             // 原来是fe
	 mac_addr[11]<=8'hc0;
	 mac_addr[12]<=8'h08;                //0800: IP包类型
	 mac_addr[13]<=8'h00;
	 i<=0;
 end


//UDP数据发送程序	 
always@(negedge clk)
begin		
		case(tx_state)
		  idle:begin
				 txer<=1'b0;
				 txen<=1'b0;
				 crcen<=1'b0;
				 crcre<=1;
				 j<=0;
				 dataout<=0;
				 ram_rd_addr<=1;
				 tx_data_counter<=0;
//             if (time_counter==32'h125) begin     //等待延迟, 每隔一段时间发送一个数据包，值越小，包发送之间的间隔越小
//				     tx_state<=start;  
//                 time_counter<=0;
//             end
//             else
//                 time_counter<=time_counter+1'b1;	
                if (rdy1) begin     //等待延迟, 每隔一段时间发送一个数据包，值越小，包发送之间的间隔越小
                tx_state<=start;  
                ram_rd_addr<=1;
                end 
                else if(rdy2) begin
                tx_state<=start;  
                ram_rd_addr<=251;
                end     			
			end

		   start:begin        //IP header
					ip_header[0]<={16'h4500,tx_total_length};        //版本号：4； 包头长度：20；IP包总长
				   ip_header[1][31:16]<=ip_header[1][31:16]+1'b1;   //包序列号
					ip_header[1][15:0]<=16'h4000;                    //Fragment offset
				   ip_header[2]<=32'h80110000;                      //mema[2][15:0] 协议：17(UDP)
				   ip_header[3]<=32'hc0a86439;                      //192.168.100.58源地址  51  52 53--35  hs1: 54-36   hs2:55-37  hs3:56-38     hs4: 57-39 hs5 58 -3a
				   ip_header[4]<=32'hc0a86443;                      //192.168.100.68目的地址 61 62  3e 63-3F hs1:  64-40  hs2: 65-41  hs3: 66-42  hs4: 67-43   hs5:67 -44
					ip_header[5]<=32'h1f901f90;                      //2个字节的源端口号和2个字节的目的端口号
				   ip_header[6]<={tx_data_length,16'h0000};         //2个字节的数据长度和2个字节的校验和（无）
	   			tx_state<=make;
         end	
         make:begin            //生成包头的校验和
			    if(i==0) begin
					  check_buffer<=ip_header[0][15:0]+ip_header[0][31:16]+ip_header[1][15:0]+ip_header[1][31:16]+ip_header[2][15:0]+
					               ip_header[2][31:16]+ip_header[3][15:0]+ip_header[3][31:16]+ip_header[4][15:0]+ip_header[4][31:16];
                 i<=i+1'b1;
				   end
             else if(i==1) begin
					   check_buffer[15:0]<=check_buffer[31:16]+check_buffer[15:0];
					   i<=i+1'b1;
				 end
			    else	begin
				      ip_header[2][15:0]<=~check_buffer[15:0];                 //header checksum
					   i<=0;
					   tx_state<=send55;
					end
		   end
			send55: begin                    //发送8个IP前导码:7个55, 1个d5                    
 				 txen<=1'b1;                             //GMII数据发送有效
				 crcre<=1'b1;                            //reset crc  
				 if(i==7) begin
               dataout[7:0]<=preamble[i][7:0];
					i<=0;
				   tx_state<=sendmac;
				 end
				 else begin                        
				    dataout[7:0]<=preamble[i][7:0];
				    i<=i+1;
				 end
			end	
			sendmac: begin                           //发送目标MAC address和源MAC address和IP包类型  
			 	 crcen<=1'b1;                            //crc校验使能，crc32数据校验从目标MAC开始		
				 crcre<=1'b0;                            			
             if(i==13) begin
               dataout[7:0]<=mac_addr[i][7:0];
					i<=0;
				   tx_state<=sendheader;
				 end
				 else begin                        
				    dataout[7:0]<=mac_addr[i][7:0];
				    i<=i+1'b1;
				 end
			end
			sendheader: begin                        //发送7个32bit的IP 包头
				datain_reg<=datain;                   //准备需要发送的数据	
			   if(j==6) begin                        //发送ip_header[6]                   
					  if(i==0) begin
						 dataout[7:0]<=ip_header[j][31:24];
						 i<=i+1'b1;
					  end
					  else if(i==1) begin
						 dataout[7:0]<=ip_header[j][23:16];
						 i<=i+1'b1;
					  end
					  else if(i==2) begin
						 dataout[7:0]<=ip_header[j][15:8];
						 i<=i+1'b1;
					  end
					  else if(i==3) begin
						 dataout[7:0]<=ip_header[j][7:0];
						 i<=0;
						 j<=0;
						 tx_state<=senddata;			 
					  end
					  else
						 txer<=1'b1;
				end		 
				else begin                                   //发送ip_header[0]~ip_header[5]   
					  if(i==0) begin
						 dataout[7:0]<=ip_header[j][31:24];
						 i<=i+1'b1;
					  end
					  else if(i==1) begin
						 dataout[7:0]<=ip_header[j][23:16];
						 i<=i+1'b1;
					  end
					  else if(i==2) begin
						 dataout[7:0]<=ip_header[j][15:8];
						 i<=i+1'b1;
					  end
					  else if(i==3) begin
						 dataout[7:0]<=ip_header[j][7:0];
						 i<=0;
						 j<=j+1'b1;
					  end					
					  else
						 txer<=1'b1;
				end
			 end
			 senddata:begin                                      //发送UDP数据包
			   if(tx_data_counter==tx_data_length-9) begin       //判断是否是发送最后的数据(真正的数据包长度是tx_data_length-8）
				   tx_state<=sendcrc;	                          //发送最后一个字节,状态转到sendcrc
					if(i==0) begin    
					  dataout[7:0]<=datain_reg[31:24];
					  i<=0;
					end
					else if(i==1) begin
					  dataout[7:0]<=datain_reg[23:16];
					  i<=0;
					end
					else if(i==2) begin
					  dataout[7:0]<=datain_reg[15:8];
					  i<=0;
					end
					else if(i==3) begin
			        dataout[7:0]<=datain_reg[7:0];
					  datain_reg<=datain;                       //提前准备数据
					  i<=0;
					end
            end
            else begin                                     //发送其它的数据包(第一个字节到倒数第二个字节）
               tx_data_counter<=tx_data_counter+1'b1;			
					if(i==0) begin    
					  dataout[7:0]<=datain_reg[31:24];	       //发送高8位(31：24）数据
					  i<=i+1'b1;
					  ram_rd_addr<=ram_rd_addr+1'b1;           //RAM地址加1, 提前让RAM输出数据	
					end
					else if(i==1) begin
					  dataout[7:0]<=datain_reg[23:16];         //发送次高8位(23：16）数据
					  i<=i+1'b1;
					end
					else if(i==2) begin
					  dataout[7:0]<=datain_reg[15:8];          //发送次低8位(15：8）数据
					  i<=i+1'b1;
					end
					else if(i==3) begin
			        dataout[7:0]<=datain_reg[7:0];           //发送低8位(7：0）数据
					  datain_reg<=datain;                      //准备数据					  
					  i<=0; 				  
					end
				end
			end	
			sendcrc: begin                              //发送32位的crc校验
				crcen<=1'b0;
				if(i==0)	begin
					  dataout[7:0] <= {~crc[24], ~crc[25], ~crc[26], ~crc[27], ~crc[28], ~crc[29], ~crc[30], ~crc[31]};
					  i<=i+1'b1;
					end
				else begin
				  if(i==1) begin
					   dataout[7:0]<={~crc[16], ~crc[17], ~crc[18], ~crc[19], ~crc[20], ~crc[21], ~crc[22], ~crc[23]};
						i<=i+1'b1;
				  end
				  else if(i==2) begin
					   dataout[7:0]<={~crc[8], ~crc[9], ~crc[10], ~crc[11], ~crc[12], ~crc[13], ~crc[14], ~crc[15]};
						i<=i+1'b1;
				  end
				  else if(i==3) begin
					   dataout[7:0]<={~crc[0], ~crc[1], ~crc[2], ~crc[3], ~crc[4], ~crc[5], ~crc[6], ~crc[7]};
						i<=0;
						tx_state<=idle;
				  end
				  else begin
                  txer<=1'b1;
				  end
				end
			end					
			default:tx_state<=idle;		
       endcase	  
 end
endmodule





