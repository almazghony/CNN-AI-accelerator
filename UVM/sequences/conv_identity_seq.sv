`ifndef CONV_IDENTITY_SEQ
    `define CONV_IDENTITY_SEQ
    
    class conv_identity_seq extends conv_base_seq;
        `uvm_object_utils(conv_identity_seq)
        function new(string name="conv_identity_seq"); super.new(name); endfunction
        task body();
            // identity kernel: center = 1
            foreach (kernel[i])
                kernel[i] = (i == 4) ? 8'sd1 : 8'sd0;

            // ramp image
            for (int r = 0; r < 32; r++)
                for (int c = 0; c < 32; c++)
                    image[r][c] = (r*32 + c) % 256;
            program_kernel();
            pulse_start();
            stream_image(0);
            wait_done();        
        endtask
    endclass
    
`endif