`ifndef CONV_MON_SEQ_re
`define CONV_MON_SEQ_re
class conv_mon_tr extends uvm_sequence_item;
    // snapshot of one clock's worth of interface activity
    bit                          rst_n;
    bit                          start;
    bit                          kernel_we;
    bit [7:0]                    kernel_addr;
    bit [7:0]                    kernel_data;
    bit [7:0]                    pixel_in;
    bit                          pixel_valid;
    bit signed [15:0]            pixel_out;
    bit                          pixel_out_valid;
    bit                          done;
    bit                          busy;

    `uvm_object_utils(conv_mon_tr)

    function new(string name = "conv_mon_tr");
        super.new(name);
    endfunction
endclass
`endif