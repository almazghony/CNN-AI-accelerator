`ifndef CONV_RANDOM_SEQ
    `define CONV_RANDOM_SEQ

    class conv_random_seq extends conv_base_seq;
        `uvm_object_utils(conv_random_seq)
        
        rand bit signed [WGT_WIDTH-1:0] k_tmp[K_DIM*K_DIM]; 


        function new(string name="conv_random_seq"); 
            super.new(name); 
        endfunction

        task body();
            if (!randomize(k_tmp)) 
                `uvm_fatal("SEQ","rand kernel failed")

            foreach (kernel[i]) kernel[i] = k_tmp[i];
            for (int r = 0; r < IMG_MAX_H; r++)
                for (int c = 0; c < IMG_MAX_W; c++)
                    image[r][c] = $urandom_range(0, (1 << PIX_WIDTH) - 1);
            program_kernel();
            pulse_start();
            stream_image(2);
            wait_done();
        endtask
    endclass
    
`endif