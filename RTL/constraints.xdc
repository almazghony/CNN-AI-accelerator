## PYNQ-Z2 — XC7Z020-1CLG400C

## 200 MHz PL clock
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -name sys_clk -period 5.000 [get_ports clk]
