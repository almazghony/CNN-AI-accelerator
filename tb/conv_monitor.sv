`ifndef CONV_MONITOR_SV
`define CONV_MONITOR_SV

class conv_monitor extends uvm_monitor;
    `uvm_component_utils(conv_monitor)

    virtual conv_if vif;
    uvm_analysis_port #(conv_mon_tr) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction


    task run_phase(uvm_phase phase);
        conv_mon_tr item;
        forever begin
            @(vif.mon_cb);
            item = conv_mon_tr::type_id::create("item");

            item.rst_n           <= vif.mon_cb.rst_n;
            item.start           <= vif.mon_cb.start;
            item.kernel_we       <= vif.mon_cb.kernel_we;
            item.kernel_addr     <= vif.mon_cb.kernel_addr;
            item.kernel_data     <= vif.mon_cb.kernel_data;
            item.pixel_in        <= vif.mon_cb.pixel_in;
            item.pixel_valid     <= vif.mon_cb.pixel_valid;
            item.pixel_out       <= vif.mon_cb.pixel_out;
            item.pixel_out_valid <= vif.mon_cb.pixel_out_valid;
            item.done            <= vif.mon_cb.done;
            item.busy            <= vif.mon_cb.busy;

            ap.write(item);
        end
    endtask
endclass
`endif
