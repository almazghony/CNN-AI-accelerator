vdel -all
vlib work
vlog -f files.f
vsim -voptargs=+acc work.tb_top
add wave -group "top"                       /tb_top/dut/*
add wave -group "TB"                        /tb_top/* /tb_top/result /tb_top/image
add wave -group "u_global_ctrl"             /tb_top/dut/u_global_ctrl/*
add wave -group "u_input_ctrl"              /tb_top/dut/u_input_ctrl/*
add wave -group "u_kernel_mem"              /tb_top/dut/u_kernel_mem/*
add wave -group "u_sliding_window"          /tb_top/dut/u_sliding_window/* tb_top/dut/u_sliding_window/lb
add wave -group "u_MAC_array"               /tb_top/dut/u_MAC_array/*
add wave -group "u_accumulator"             /tb_top/dut/u_accumulator/*
add wave -group "u_relu"                    /tb_top/dut/u_relu/*
add wave -group "u_output_formatter"        /tb_top/dut/u_output_formatter/*
add wave -group "u_output_ctrl"             /tb_top/dut/u_output_ctrl/*
configure wave -namecolwidth 220
configure wave -valuecolwidth 120
configure wave -signalnamewidth 5


run -all
wave zoom full
