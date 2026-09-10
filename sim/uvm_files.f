// sim/uvm_files.f — UVM flow file list (Questa/ModelSim `vlog -sv -f`).
// Paths are relative to sim/ (vlog is invoked from sim/).
// +incdir order matters: the tb includes (conv_*.sv) reference the package
// conv_pkg, whose params size the interface ports — so BOTH ../RTL (for
// conv_pkg.sv via CNN_accelerator.sv) and ../tb (for tb-side includes) must
// be on the include path.
+incdir+../RTL
+incdir+../tb
../RTL/CNN_accelerator.sv
../tb/conv_if.sv
../tb/tb_top_uvm.sv
