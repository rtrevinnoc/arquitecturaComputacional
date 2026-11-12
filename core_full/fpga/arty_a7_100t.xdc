## Constraints para TopArtyA7.sv en el Arty A7-100T (Rev. D/E, xc7a100tcsg324-1).
## Pines tomados del master XDC oficial de Digilent:
## https://github.com/Digilent/digilent-xdc/blob/master/Arty-A7-100-Master.xdc

## Reloj de 100 MHz de la placa
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK100MHZ }];

## Botones (btn[0] = reset del nucleo)
set_property -dict { PACKAGE_PIN D9  IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN C9  IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];
set_property -dict { PACKAGE_PIN B9  IOSTANDARD LVCMOS33 } [get_ports { btn[2] }];
set_property -dict { PACKAGE_PIN B8  IOSTANDARD LVCMOS33 } [get_ports { btn[3] }];

## Switches (indice de registro a mostrar, x0-x15)
set_property -dict { PACKAGE_PIN A8  IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN C11 IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN C10 IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN A10 IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

## LEDs verdes (nibble bajo del registro elegido)
set_property -dict { PACKAGE_PIN H5  IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN J5  IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## Canal rojo de los 4 LEDs RGB (nibble alto del registro elegido)
set_property -dict { PACKAGE_PIN G6  IOSTANDARD LVCMOS33 } [get_ports { led0_r }];
set_property -dict { PACKAGE_PIN G3  IOSTANDARD LVCMOS33 } [get_ports { led1_r }];
set_property -dict { PACKAGE_PIN J3  IOSTANDARD LVCMOS33 } [get_ports { led2_r }];
set_property -dict { PACKAGE_PIN K1  IOSTANDARD LVCMOS33 } [get_ports { led3_r }];

## Canal azul del LED RGB 3 (parpadeo de vida, ~1.5 Hz)
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { led3_b }];

## Reloj del nucleo: 100 MHz / 8 (el monociclo no cierra timing a 100 MHz)
create_generated_clock -name core_clk -source [get_ports CLK100MHZ] -divide_by 8 [get_pins clk_div_reg[2]/Q]

## USB-UART de la placa (FTDI): linea FPGA -> PC (115200 8N1), traza de instrucciones
set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }];

## La salida de retiro (dominio core_clk) solo se muestrea con el reloj del nucleo
## detenido, asi que no es un camino de un solo ciclo de 100 MHz.
set_false_path -from [get_clocks core_clk] -to [get_clocks sys_clk_pin]
