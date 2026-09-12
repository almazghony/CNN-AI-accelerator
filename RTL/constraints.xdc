## PYNQ-Z2 — XC7Z020-1CLG400C

## 200 MHz PL clock
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -name sys_clk -period 5.000 [get_ports clk]

## Push buttons
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports btn_reset]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports btn_start]

## LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports led_busy]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports led_done]