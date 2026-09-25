vdel -all
vlib work

vlog -sv -f files.f

# copy python golden model next to the sim working dir (scoreboard $system calls it there)
file copy -force ../UVM/env/scoreboard/golden_model.py ./golden_model.py


vsim -c -voptargs=+acc work.tb_top_uvm \
+UVM_TESTNAME=conv_multi_random_test \
+UVM_VERBOSITY=UVM_LOW
set NoQuitOnFinish 1

power add -r /tb_top_uvm/dut/*
power report -all -bsaif my_design.saif

add wave -group "top"                       /tb_top_uvm/dut/*
add wave -group "u_global_ctrl"             /tb_top_uvm/dut/u_global_ctrl/*
add wave -group "u_input_ctrl"              /tb_top_uvm/dut/u_input_ctrl/*
add wave -group "u_kernel_mem"              /tb_top_uvm/dut/u_kernel_mem/*
add wave -group "u_sliding_window"          /tb_top_uvm/dut/u_sliding_window/* tb_top_uvm/dut/u_sliding_window/lb
add wave -group "u_MAC_array"               /tb_top_uvm/dut/u_MAC_array/*
add wave -group "u_relu"                    /tb_top_uvm/dut/u_relu/*
add wave -group "u_output_formatter"        /tb_top_uvm/dut/u_output_formatter/*
add wave -group "u_output_ctrl"             /tb_top_uvm/dut/u_output_ctrl/*
configure wave -namecolwidth 220
configure wave -valuecolwidth 120
configure wave -signalnamewidth 10

run -all
