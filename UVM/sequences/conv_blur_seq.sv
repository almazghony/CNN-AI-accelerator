`ifndef CONV_BLUR_SEQ
    `define CONV_BLUR_SEQ
    
    // 3) All-ones blur kernel + ramp (checks accumulation path)
    class conv_blur_seq extends conv_base_seq;
        `uvm_object_utils(conv_blur_seq)
        function new(string name="conv_blur_seq"); 
            super.new(name); 
        endfunction
        
        task body();
            foreach (kernel[i])
                kernel[i] = 8'sd1;

            for (int r = 0; r < IMG_MAX_H; r++)
                for (int c = 0; c < IMG_MAX_W; c++)
                    image[r][c] = (r*IMG_MAX_H + c) % $clog2(PIX_WIDTH);
            program_kernel();
            pulse_start();
            stream_image(0);
            wait_done();
        endtask
    endclass

`endif
