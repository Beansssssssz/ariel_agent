class avalon_st_driver #(int DATA_WIDTH_IN_BYTES = 4, int unsigned VALID_RDY_PERCENTAGE = 100, bit IS_MASTER = 1'b1);

    virtual avalon_st_if #(DATA_WIDTH_IN_BYTES) vif;

    function new(virtual avalon_st_if #(DATA_WIDTH_IN_BYTES) vif);
        this.vif = vif;

        // If its slave start a fork to always change the data
        if(~IS_MASTER) begin
            fork
                drive_slave();
            join_none
        end
    endfunction

        // Drives the master signals based on the received value
    // ─── Helper: pack a byte queue into words ───────────────────────────────────
    function automatic void bytes_to_words(
        input  byte                                          data[$],
        output logic [DATA_WIDTH_IN_BYTES*8-1:0]             words[$]
    );
        int num_words;
        int byte_idx;

        words.delete();
        num_words = (data.size() + DATA_WIDTH_IN_BYTES - 1) / DATA_WIDTH_IN_BYTES;

        for (int w = 0; w < num_words; w++) begin
            logic [DATA_WIDTH_IN_BYTES*8-1:0] word = '0;
            for (int b = 0; b < DATA_WIDTH_IN_BYTES; b++) begin
                byte_idx = w * DATA_WIDTH_IN_BYTES + b;
                if (byte_idx < data.size())
                    // place byte b at its lane; adjust endianness here if needed
                    word[b*8 +: 8] = data[byte_idx];
            end
            words.push_back(word);
        end
    endfunction

    task drive_master(byte data[$]);
        logic [DATA_WIDTH_IN_BYTES * $bits(byte) - 1 : 0] words[$];
        int num_words;
        bit valid;

        // Build the word array from the raw byte stream
        words = {<<DATA_WIDTH_IN_BYTES{data}};
        num_words = words.size();
        valid     = 1'b0;

        // Drive each word
        while (words.size() > 0) begin

            // Sync with clock
            @(vif.master_cb);

            // Send SOP only if its first word
            vif.master_cb.sop   <= (words.size() == 0);

            // Send EOP only if current word is last
            vif.master_cb.eop   <= (words.size() == 1);

               // iF valid if true, hold it until transaction
            if (!valid)
                valid = rand_bit();
            vif.master_cb.valid <= valid;

            // Send current first word
            vif.master_cb.data  <= words[0];

            // empty is meaningful only on the last word
            vif.master_cb.empty <= (DATA_WIDTH_IN_BYTES - (data.size() % DATA_WIDTH_IN_BYTES)) % DATA_WIDTH_IN_BYTES;


            if (valid) begin
                @(vif.master_cb iff (vif.master_cb.rdy === 1'b1));
                valid = 1'b0;
                words.pop_front();
            end
        end

        // Reset the data inside.
        @(vif.master_cb);
        vif.CLEAR_MASTER_CB();
    endtask

    // Drives the slave signals in a infinite loop
    task drive_slave();

        // infinite loop, meaning always alter the rdy value
        forever @(vif.slave_cb) begin
            vif.slave_cb.rdy <= rand_bit();
        end
    endtask

    function bit rand_bit();
        std::randomize(rand_bit) with {
            rand_bit dist {
                1'b1 := VALID_RDY_PERCENTAGE,
                1'b0 := (100 - VALID_RDY_PERCENTAGE)
            };
        };
    endfunction
endclass