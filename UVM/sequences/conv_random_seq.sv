`ifndef CONV_RANDOM_SEQ
    `define CONV_RANDOM_SEQ

    // 2) Random kernel + random image
    class conv_random_seq extends conv_base_seq;
        `uvm_object_utils(conv_random_seq)
        rand bit signed [7:0] k_tmp[9];
        function new(string name="conv_random_seq"); super.new(name); endfunction
        task body();
            if (!randomize(k_tmp)) `uvm_fatal("SEQ","rand kernel failed")
            foreach (kernel[i]) kernel[i] = k_tmp[i];
            for (int r = 0; r < 32; r++)
                for (int c = 0; c < 32; c++)
                    image[r][c] = $urandom_range(0,255);
            do_reset(5);
            program_kernel();
            pulse_start();
            stream_image(2); // small random gaps
        endtask
    endclass
    
`endif