// -----------------------------------------------------------------------------
// File        : avalon_st_agent_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

`include "design.sv"
`include "avalon_st_driver.sv"


module tb ();

    //////////////////////////////////////////////////////////////////////////////
    // Parameters.
    //////////////////////////////////////////////////////////////////////////////
    // Data width.
    localparam int unsigned DATA_WIDTH_IN_BYTES = 4;

    //////////////////////////////////////////////////////////////////////////////
    // Declarations.
    //////////////////////////////////////////////////////////////////////////////
    // Clock and reset.
    bit clk;
    bit rst_n;

    // Interface declaration.
    avalon_st_if#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif (.clk(clk));
    avalon_st_driver master_driver;
    avalon_st_driver slave_driver;

    byte data_to_send[$];

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////
    // Generate clock.
    initial begin
        master_driver = new (vif, 70);
      slave_driver = new (vif, 70, 1'b1);
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Initialize reset signal.
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Timeout.
    initial begin
        #(10000) $finish;
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
        create_random_byte_array(data_to_send);
        master_driver.drive(data_to_send);
    end

    task create_random_byte_array(output byte data[$]);
        int unsigned length;
        byte current_byte;

        // Creating random length
        std::randomize(length) with {
            length inside {[1 : 1000]}; 
        };
        
        // Creating random byte array
        for(int i = 0; i < length; i++) begin
            std::randomize(current_byte);
            data.push_front(current_byte);
        end
    endtask
endmodule