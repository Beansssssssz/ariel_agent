class avalon_st_driver #(int DATA_WIDTH_IN_BYTES = 4, int unsigned VALID_RDY_PERCENTAGE = 100, bit IS_MASTER = 1'b1);

    virtual avalon_st_if #(DATA_WIDTH_IN_BYTES) vif;

    import agent_pack::queue_byte;

    function new(virtual avalon_st_if #(DATA_WIDTH_IN_BYTES) vif);
        this.vif = vif;

        // If its slave start a fork to always change the data
        if(~IS_MASTER) begin
            fork
                drive_slave();
            join_none
        end
    endfunction

    task drive_master(queue_byte data);
        bit [DATA_WIDTH_IN_BYTES * $bits(byte) - 1 : 0] words[$];
        int num_words;

        // Build the word array from the raw byte stream
        words = {<<DATA_WIDTH_IN_BYTES{data}};
        num_words = words.size();

        // Drive each word
        while (words.size() > 0) begin

            // Send real word
            if(rand_bit()) begin
                // Send SOP only if its first word
                vif.master_cb.sop <= (words.size() == num_words);

                // Send EOP only if current word is last
                vif.master_cb.eop <= (words.size() == 1);

                // Randomize valid
                vif.master_cb.valid <= 1'b1;

                // Send current first word
                vif.master_cb.data  <= words.pop_front();

                // empty is meaningful only on the last word
                vif.master_cb.empty <= (DATA_WIDTH_IN_BYTES - (data.size() % DATA_WIDTH_IN_BYTES)) % DATA_WIDTH_IN_BYTES;

                // Wait until rdy
                @(vif.master_cb iff (vif.master_cb.rdy) );

            // Generate random data without valid
            end else begin
                this.randomize_interface_data();
                vif.master_cb.valid <= 1'b0;
            end

            // Sync with clock
            @(vif.master_cb);
        end

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

    function bit randomize_interface_data();
            vif.master_cb.sop <= $urandom();
            vif.master_cb.eop <= $urandom();
            vif.master_cb.data  <= $urandom();
            vif.master_cb.empty <= $urandom();
    endfunction
endclass
