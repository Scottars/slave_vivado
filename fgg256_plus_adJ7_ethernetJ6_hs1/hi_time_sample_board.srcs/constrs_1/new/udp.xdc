set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#############SPI Configurate Setting##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
############## clock define###########################

#create_clock -period 5.000 [get_ports sys_clk_p]
#set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
#set_property PACKAGE_PIN T4 [get_ports sys_clk_n]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_p]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_n]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk_50M]
set_property PACKAGE_PIN D4 [get_ports sys_clk_50M]


##########ad管脚的时钟的输出   A18 就是ad采样芯片的时钟的管脚输入。
set_property IOSTANDARD LVCMOS33 [get_ports ad1_clk]
set_property PACKAGE_PIN A5 [get_ports ad1_clk]

set_property IOSTANDARD LVCMOS33 [get_ports ad2_clk]
set_property PACKAGE_PIN H5 [get_ports ad2_clk]

############测试的ad  时钟管脚的输入
set_property IOSTANDARD LVCMOS33 [get_ports test_ad_clk]
set_property PACKAGE_PIN G4 [get_ports test_ad_clk]
############ user  led
set_property IOSTANDARD LVCMOS25 [get_ports user_led_board]
set_property PACKAGE_PIN L14 [get_ports user_led_board]

set_property IOSTANDARD LVCMOS33 [get_ports user_led_green]
set_property PACKAGE_PIN K3 [get_ports user_led_green]

set_property IOSTANDARD LVCMOS33 [get_ports user_led_yellow]
set_property PACKAGE_PIN J3 [get_ports user_led_yellow]


#################光纤入口###################
set_property IOSTANDARD LVCMOS33 [get_ports seq_1]
set_property PACKAGE_PIN H4 [get_ports seq_1]


################ad data line port###############
set_property IOSTANDARD LVCMOS33 [get_ports {ad1_data[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ad2_data[*]}]

set_property PACKAGE_PIN B2 [get_ports {ad1_data[0]}]
set_property PACKAGE_PIN E5 [get_ports {ad1_data[1]}]
set_property PACKAGE_PIN A2 [get_ports {ad1_data[2]}]
set_property PACKAGE_PIN F5 [get_ports {ad1_data[3]}]
set_property PACKAGE_PIN A3 [get_ports {ad1_data[4]}]
set_property PACKAGE_PIN D5 [get_ports {ad1_data[5]}]
set_property PACKAGE_PIN B4 [get_ports {ad1_data[6]}]
set_property PACKAGE_PIN D6 [get_ports {ad1_data[7]}]
set_property PACKAGE_PIN B5 [get_ports {ad1_data[8]}]
set_property PACKAGE_PIN A7 [get_ports {ad1_data[9]}]
set_property PACKAGE_PIN B6 [get_ports {ad1_data[10]}]
set_property PACKAGE_PIN B7 [get_ports {ad1_data[11]}]

set_property PACKAGE_PIN G5 [get_ports {ad2_data[0]}]
set_property PACKAGE_PIN G1 [get_ports {ad2_data[1]}]
set_property PACKAGE_PIN F3 [get_ports {ad2_data[2]}]
set_property PACKAGE_PIN G2 [get_ports {ad2_data[3]}]
set_property PACKAGE_PIN F4 [get_ports {ad2_data[4]}]
set_property PACKAGE_PIN F2 [get_ports {ad2_data[5]}]
set_property PACKAGE_PIN C2 [get_ports {ad2_data[6]}]
set_property PACKAGE_PIN E1 [get_ports {ad2_data[7]}]
set_property PACKAGE_PIN C3 [get_ports {ad2_data[8]}]
set_property PACKAGE_PIN D1 [get_ports {ad2_data[9]}]
set_property PACKAGE_PIN E3 [get_ports {ad2_data[10]}]
set_property PACKAGE_PIN C1 [get_ports {ad2_data[11]}]


#########################ethernet######################
set_property IOSTANDARD LVCMOS25 [get_ports {e_rxd[*]}]
set_property IOSTANDARD LVCMOS25 [get_ports {e_txd[*]}]
set_property SLEW FAST [get_ports {e_txd[*]}]

set_property IOSTANDARD LVCMOS25 [get_ports e_mdc]
set_property IOSTANDARD LVCMOS25 [get_ports e_mdio]

set_property IOSTANDARD LVCMOS25 [get_ports e_gtxc]
set_property SLEW FAST [get_ports e_gtxc]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets e_gtxc_OBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets e_gtxc]
set_property IOSTANDARD LVCMOS25 [get_ports e_txc]
set_property IOSTANDARD LVCMOS25 [get_ports e_txer]
set_property IOSTANDARD LVCMOS25 [get_ports e_txen]
set_property SLEW FAST [get_ports e_txer]
set_property IOSTANDARD LVCMOS25 [get_ports e_rxc]
set_property IOSTANDARD LVCMOS25 [get_ports e_rxdv]
set_property IOSTANDARD LVCMOS25 [get_ports e_rxer]
set_property IOSTANDARD LVCMOS25 [get_ports e_reset]
set_property SLEW FAST [get_ports e_txen]
set_property SLEW FAST [get_ports e_reset]
###########thernet pin part ########
set_property PACKAGE_PIN M6 [get_ports e_mdc]
set_property PACKAGE_PIN P6 [get_ports e_mdio]

set_property PACKAGE_PIN P9 [get_ports e_reset]


set_property PACKAGE_PIN T9 [get_ports e_gtxc]
set_property PACKAGE_PIN R8 [get_ports e_txc]
set_property PACKAGE_PIN P10 [get_ports e_txen]
set_property PACKAGE_PIN R5 [get_ports e_txer]


set_property PACKAGE_PIN T8 [get_ports {e_txd[0]}]
set_property PACKAGE_PIN T7 [get_ports {e_txd[1]}]
set_property PACKAGE_PIN N9 [get_ports {e_txd[2]}]
set_property PACKAGE_PIN R7 [get_ports {e_txd[3]}]
set_property PACKAGE_PIN R6 [get_ports {e_txd[4]}]
set_property PACKAGE_PIN P8 [get_ports {e_txd[5]}]
set_property PACKAGE_PIN T5 [get_ports {e_txd[6]}]
set_property PACKAGE_PIN N6 [get_ports {e_txd[7]}]

set_property PACKAGE_PIN N11 [get_ports e_rxc]
set_property PACKAGE_PIN P14 [get_ports e_rxdv]
set_property PACKAGE_PIN R12 [get_ports e_rxer]


set_property PACKAGE_PIN T14 [get_ports {e_rxd[0]}]
set_property PACKAGE_PIN N14 [get_ports {e_rxd[1]}]
set_property PACKAGE_PIN N12 [get_ports {e_rxd[2]}]
set_property PACKAGE_PIN T13 [get_ports {e_rxd[3]}]
set_property PACKAGE_PIN R13 [get_ports {e_rxd[4]}]
set_property PACKAGE_PIN R11 [get_ports {e_rxd[5]}]
set_property PACKAGE_PIN T12 [get_ports {e_rxd[6]}]
set_property PACKAGE_PIN R10 [get_ports {e_rxd[7]}]





#############这个是light 2 连接的是右数第三个################
set_property PACKAGE_PIN J5 [get_ports ext_bcode]
set_property IOSTANDARD LVCMOS33 [get_ports ext_bcode]


