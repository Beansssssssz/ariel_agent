
class avalon_st_sequencer #();
    import  agent_pack::*;

    byte array_of_packets[$][$];

    function new();
        create_random_byte_array(array_of_packets);
    endfunction

    task get_new_packet(output byte current_packet[$]);
        current_packet = array_of_packets.pop_front();

        // Request new data
        if(current_packet.size() == 0)
            create_random_byte_array(array_of_packets);
    endtask

    task create_random_byte_array(output byte data[$][$]);

        // Creating random byte array
        std::randomize(data) with {
            
            // Setting num of packet.
            data.size() inside {[1 : MAX_NUM_OF_MESSAGES]}; 

            // Setting data inside each packet.
            foreach(data[i]) {
                data[i].size() inside {[1 : MAX_MESSAGE_SIZE_IN_BYTES]}; 
            }
        };
    endtask
endclass