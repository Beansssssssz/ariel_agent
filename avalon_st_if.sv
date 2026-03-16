// -----------------------------------------------------------------------------
// File        : avalon_st_if.sv
// Author      : Yuval Heby
// Description : Avalon Streaming Interface class.
// -----------------------------------------------------------------------------

`ifndef __AVALON_ST_IF
`define __AVALON_ST_IF

interface avalon_st_if #(int unsigned DATA_WIDTH_IN_BYTES = 4)(input logic clk);
    
    //////////////////////////////////////////////////////////////////////////////
    // Interface Signals.
    //////////////////////////////////////////////////////////////////////////////
    logic                                             valid;
    logic                                             rdy;
    logic                                             sop;
    logic                                             eop;
    logic [DATA_WIDTH_IN_BYTES * $bits(byte) - 1 : 0] data;
    logic [$clog2(DATA_WIDTH_IN_BYTES)       - 1 : 0] empty;

    //////////////////////////////////////////////////////////////////////////////
    // Modports.
    //////////////////////////////////////////////////////////////////////////////
    // Master.
    modport master (
        input  clk,
        input  rdy,
        output valid,
        output sop,
        output eop,
        output data,
        output empty
    );

    // Slave.
    modport slave (
        input  clk,
        input  valid,
        input  sop,
        input  eop,
        input  data,
        input  empty,
        output rdy
    );

    // Monitor.
    modport monitor (
        input  clk,
        input  valid,
        input  rdy,
        input  sop,
        input  eop,
        input  data,
        input  empty
    );

    //////////////////////////////////////////////////////////////////////////////
    // Clocking Blocks.
    //////////////////////////////////////////////////////////////////////////////
    // Master Clocking Block.
    clocking master_cb @(posedge clk);
        default input #1step output #1;
        input  rdy;
        output valid, sop, eop, data, empty;
    endclocking

    // Slave Clocking Block.
    clocking slave_cb @(posedge clk);
        default input #1step output #1;
        input  valid, sop, eop, data, empty;
        output rdy;
    endclocking

    // Monitor Clocking Block.
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input valid, rdy, sop, eop, data, empty;
    endclocking

    //////////////////////////////////////////////////////////////////////////////
    // Methods.
    //////////////////////////////////////////////////////////////////////////////
    // Clears the Master clocking block signals
    function void CLEAR_MASTER_CB();
        master_cb.valid <= 1'b0;
        master_cb.sop   <= 1'b0;
        master_cb.eop   <= 1'b0;
        master_cb.data  <= '0;
        master_cb.empty <= '0;
    endfunction

    // Clears the Slave clocking block signals
    function void CLEAR_SLAVE_CB();
        slave_cb.rdy <= 1'b0;
    endfunction
endinterface

`endif