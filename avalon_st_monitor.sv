
class avalon_st_monitor #(int DATA_WIDTH_IN_BYTES = 4);

    import agent_pack::*;

    virtual avalon_st_if #(DATA_WIDTH_IN_BYTES) vif;
    local bit[DATA_WIDTH_IN_BYTES * $bits(byte) - 1: 0] words[$];
    local byte packets[$][$];

    function new(virtual avalon_st_if #(DATA_WIDTH_IN_BYTES) vif);
        this.vif = vif;

        fork
            enforce_interface();
            save_data();
        join_none
        
    endfunction

    function int get_length_of_words();
        return words.size();
    endfunction;

    function bit[DATA_WIDTH_IN_BYTES * $bits(byte) - 1: 0] get_word_by_index(int index);
        if(index > words.size() || index < 0)
            return '0;
        return words[index];
    endfunction;

    function queue_byte get_packet_by_index(int index);
        if(index > packets.size() || index < 0)
            return {};
        return packets[index];
    endfunction;

    task enforce_interface();
        bit inside_msg;

         forever @(this.vif.monitor_cb iff (this.vif.monitor_cb.valid && this.vif.monitor_cb.rdy)) begin

            // Sop checks 
            if (vif.monitor_cb.sop) begin
                if (inside_msg)
                    $fatal("Multiple sop detected");
                inside_msg = 1'b1;
            end

            // Eop check
            if (vif.monitor_cb.eop) begin
                inside_msg = 1'b0;
            end

            // Valid outside of packet
            if (!vif.monitor_cb.sop && !vif.monitor_cb.eop && !sop_was_high)
                $fatal("Transaction outside of packet");

            // Empty field value check
            if (vif.monitor_cb.valid && vif.monitor_cb.empty >= DATA_WIDTH_IN_BYTES)
                $fatal("empty value too large — empty=%0d",vif.monitor_cb.empty);
        end
    endtask

    task save_data();
        byte current_packet[$];
        int bytes_in_word;

        forever @(this.vif.monitor_cb iff (this.vif.monitor_cb.valid && this.vif.monitor_cb.rdy)) begin

            // Append current word
            words.push_back(vif.monitor_cb.data);

            // Capture the data
            bytes_in_word = this.vif.monitor_cb.eop ? DATA_WIDTH_IN_BYTES - vif.monitor_cb.empty : DATA_WIDTH_IN_BYTES;
            for(int i=0; i < DATA_WIDTH_IN_BYTES; i++) begin
                current_packet.push_back(vif.monitor_cb.data[i*8 +:8]);
            end

            // If packet finished append and clear current_packet
            if(vif.monitor_cb.eop) begin
                packets.push_back(current_packet);
                current_packet = {};
            end
        end
    endtask
endclass