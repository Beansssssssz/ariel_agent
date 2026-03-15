// -----------------------------------------------------------------------------
// File        : avalon_st_agent_tb.sv
// Author      : 
// Description : Top TB module for Agent Exercise.
// -----------------------------------------------------------------------------

// TODO - Add includes here!
`include "avalon_st_if.sv"

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

    // TODO - Declare your classes here.

    //////////////////////////////////////////////////////////////////////////////
    // General processes.
    //////////////////////////////////////////////////////////////////////////////
    // Generate clock.
    initial begin
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
    	vif.drive_slave(50);
    end
endmodule