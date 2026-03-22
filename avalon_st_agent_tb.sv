// -----------------------------------------------------------------------------
// File        : avalon_st_agent_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

`include "avalon_st_if.sv"
`include "avalon_st_driver.sv"
`include "agent_pack.sv"

module tb ();

    //////////////////////////////////////////////////////////////////////////////
    // Imports.
    //////////////////////////////////////////////////////////////////////////////
    import agent_pack::*;

    //////////////////////////////////////////////////////////////////////////////
    // Declarations.
    //////////////////////////////////////////////////////////////////////////////
    // Clock and reset.
    bit clk;
    bit rst_n;

    queue_byte data_to_send;

    int num_of_messages;
    int delay_between_messages;

    // Interface declaration.
    avalon_st_if#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif (.clk(clk));
    avalon_st_driver #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .VALID_RDY_PERCENTAGE(VALID_RDY_PERCENTAGE), .IS_MASTER(1'b1)) master_driver;
    avalon_st_driver #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .VALID_RDY_PERCENTAGE(VALID_RDY_PERCENTAGE), .IS_MASTER(1'b0)) slave_driver;

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////
    // Generate clock.
    initial begin
        master_driver = new (vif);
        slave_driver = new (vif);
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Initialize reset signal.
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Waves dump.
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

    //////////////////////////////////////////////////////////////////////////////
    // TestBench Logic
    //////////////////////////////////////////////////////////////////////////////
    // Test logic.
    initial begin
        // randomize how many messages to send
        std::randomize(num_of_messages) with {
            num_of_messages inside {[1 : MAX_WAIT_BETWEEN_MESSAGES]}; 
        };

        for (int i = 0; i < num_of_messages; i++) begin
            create_random_byte_array(data_to_send);
            master_driver.drive_master(data_to_send);

            // Randomize wait time between messages
            std::randomize(delay_between_messages) with {
                delay_between_messages inside {[1 : MAX_NUM_OF_MESSAGES]}; 
            };
            #delay_between_messages;
        end

        $finish("Finished tb");
    end

    task create_random_byte_array(output byte data[$]);
        localparam int MAX_MESSAGE_SIZE_IN_BYTES = 1000;

        // Creating random byte array
        std::randomize(data) with {
            data.size() inside {[1 : MAX_MESSAGE_SIZE_IN_BYTES]}; 
        };
    endtask
endmodule