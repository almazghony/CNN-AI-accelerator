# UVM regression (Questa/ModelSim). Run from sim/ dir.
# Default: identity smoke test. Override: do run_uvm.do conv_random_test
vdel -all
vlib work
# NOTE: plain vlog -sv (no -L flag). Questa/ModelSim ships precompiled UVM and
# resolves `import uvm_pkg::*` automatically; `-L uvm` would fail with
# "library not found" on most installs.
vlog -sv -f uvm_files.f
# copy python golden model next to the sim working dir (scoreboard $system calls it there)
file copy -force ../tb/golden_model.py ./golden_model.py
set TEST conv_identity_test
if { $argc > 0 } { set TEST [lindex $argv 0] }
vsim -c -voptargs=+acc work.tb_top_uvm +UVM_TESTNAME=$TEST +UVM_VERBOSITY=UVM_LOW

add wave -position insertpoint  \
sim:/tb_top_uvm/dut/clk \
sim:/tb_top_uvm/dut/rst_n \
sim:/tb_top_uvm/dut/start \
sim:/tb_top_uvm/dut/done \
sim:/tb_top_uvm/dut/busy \
sim:/tb_top_uvm/dut/kernel_we \
sim:/tb_top_uvm/dut/kernel_addr \
sim:/tb_top_uvm/dut/kernel_data \
sim:/tb_top_uvm/dut/pixel_in \
sim:/tb_top_uvm/dut/pixel_valid \
sim:/tb_top_uvm/dut/pixel_out \
sim:/tb_top_uvm/dut/pixel_out_valid \
sim:/tb_top_uvm/dut/processing_en \
sim:/tb_top_uvm/dut/output_done \
sim:/tb_top_uvm/dut/ctrl_pixel_out \
sim:/tb_top_uvm/dut/ctrl_pixel_valid \
sim:/tb_top_uvm/dut/window \
sim:/tb_top_uvm/dut/window_valid \
sim:/tb_top_uvm/dut/end_of_row \
sim:/tb_top_uvm/dut/end_of_frame \
sim:/tb_top_uvm/dut/kernel_coeffs \
sim:/tb_top_uvm/dut/partial_sum \
sim:/tb_top_uvm/dut/partial_valid \
sim:/tb_top_uvm/dut/conv_result \
sim:/tb_top_uvm/dut/conv_valid \
sim:/tb_top_uvm/dut/relu_result \
sim:/tb_top_uvm/dut/relu_valid \
sim:/tb_top_uvm/dut/fmt_pixel_out \
sim:/tb_top_uvm/dut/fmt_pixel_valid


run -all
quit
