// -----------------------------------------------------------------------------
// File        : avalon_st_agent_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

`include "avalon_st_if.sv"
`include "agent_pack.sv"
`include "avalon_st_sequencer.sv"
`include "avalon_st_driver.sv"
`include "avalon_st_monitor.sv"

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

    // Interface declaration.
    avalon_st_if#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) vif (.clk(clk));
    avalon_st_driver #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .VALID_RDY_PERCENTAGE(VALID_RDY_PERCENTAGE), .IS_MASTER(1'b1)) master_driver;
    avalon_st_driver #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES), .VALID_RDY_PERCENTAGE(VALID_RDY_PERCENTAGE), .IS_MASTER(1'b0)) slave_driver;
    avalon_st_sequencer sequencer;
    avalon_st_monitor#(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) monitor;

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////
    // Generate clock.
    initial begin
        monitor = new(vif);
        sequencer = new();
        master_driver = new (vif, sequencer);
        slave_driver = new (vif);
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Reset and stop
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
        #10000
        for (int i = 0; i < monitor.get_length_of_words(); i++) begin
            $display("word at index %d is: $h", i, monitor.get_word_by_index(i));
        end
      	$finish;
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
        master_driver.drive_master(data_to_send);
    end
endmodule