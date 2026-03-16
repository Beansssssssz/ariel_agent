class avalon_st_driver #(int DATA_WIDTH_IN_BYTES = 4);

    virtual avalon_st_if #(DATA_WIDTH_IN_BYTES) vif;
    int unsigned valid_rdy_percentage, rdy_low_percentage;
    bit slave;

    function new(input virtual avalon_st_if #(DATA_WIDTH_IN_BYTES) vif, input int unsigned VALID_RDY_PERCENTAGE = 100, input bit slave);
        valid_rdy_percentage = VALID_RDY_PERCENTAGE;
        if(VALID_RDY_PERCENTAGE >= 100)
            valid_rdy_percentage = 100;
        rdy_low_percentage = 100 - valid_rdy_percentage;

        this.vif = vif;
        this.slave = slave;

        // If its slave start a fork to always change the data
        if(slave) begin
            fork
                begin
                    drive_slave();
                end
            join_none
        end
    endfunction

    // Drives the master signals based on the received value
    task drive_master(input byte data[$]);
        int length, word_count, og_word_count, byte_index;
        bit valid;

        logic [DATA_WIDTH_IN_BYTES * $bits(byte) - 1 : 0] word;

        length = data.size();

        // correct word count
        word_count = (length + DATA_WIDTH_IN_BYTES - 1) / DATA_WIDTH_IN_BYTES;
        og_word_count = word_count;

        // Driving words
        while (word_count > 0) begin

            // pack bytes into word
            word = '0;
            for (int i = 0; i < DATA_WIDTH_IN_BYTES; i++) begin
                byte_index = (og_word_count - word_count) * DATA_WIDTH_IN_BYTES + i;

                if (byte_index < length)
                    word[i*$bits(byte) +: $bits(byte)] = data[byte_index];
            end

            // Sync clock
            @(vif.master_cb);

            // Check if current word is first
            vif.master_cb.sop   <= (og_word_count == word_count);

            // Check if current word is last
            vif.master_cb.eop   <= (word_count == 1);

            
            std::randomize(valid) with {
                valid dist {
                    1 := valid_rdy_percentage,
                    0 := rdy_low_percentage
                };
            };
            vif.master_cb.valid <= valid;

            // Send current word
            vif.master_cb.data  <= word;

            // Send empty always
            vif.master_cb.empty <= (DATA_WIDTH_IN_BYTES - (length % DATA_WIDTH_IN_BYTES)) % DATA_WIDTH_IN_BYTES;

            // If rdy is high then increase word count
            if (vif.master_cb.rdy && valid)
                word_count--;
        end

        // Reset valid after sending
        @(vif.master_cb);
        vif.master_cb.valid <= 1'b0;
    endtask

    // Drives the slave signals in a infinite loop
    task drive_slave();
        bit rdy;

        // infinite loop, meaning always alter the rdy value
        forever begin
            @(vif.slave_cb);

            std::randomize(rdy) with {
                rdy dist {
                    1 := valid_rdy_percentage,
                    0 := rdy_low_percentage
                };
            };
            vif.slave_cb.rdy <= rdy;
        end
    endtask

    // Drive data, only for master.
    task drive(input byte data_to_send[$]);
        if(this.slave) begin
            $error("Cannot call task \"drive\" for a slave driver");
            return;
        end

        drive_master(data_to_send);
    endtask
endclass