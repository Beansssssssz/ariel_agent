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

    // Drives the master signals based on the received value
    task drive_master(input byte data[$]);
        int length, word_count, og_word_count;
        int word_index, byte_index;

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
                    word[i*8 +: 8] = data[byte_index];
            end

            // Sync clock
            @(master_cb);

            // Check if current word is first
            master_cb.sop   <= (og_word_count == word_count);

            // Check if current word is last
            master_cb.eop   <= (word_count == 1);

            // Always send valid
            master_cb.valid <= 1'b1;

            // Send current word
            master_cb.data  <= word;

            // Send empty always
            master_cb.empty <= (DATA_WIDTH_IN_BYTES - (length % DATA_WIDTH_IN_BYTES)) % DATA_WIDTH_IN_BYTES;

            // If rdy is high then increase word count
            if (master_cb.rdy)
                word_count--;
        end

        // Reset valid after sending
        @(master_cb);
        master_cb.valid <= 1'b0;
    endtask

    // Since the rdy should always be active, yet not interfere with the rest of the code we fork it.
    task drive_slave(input int rdy_high_percentage);
        fork
            begin
                drive_slave_fork(rdy_high_percentage);
            end
        join_none
        
    endtask

    // Drives the master signals based on the received change
    task drive_slave_fork(input int rdy_high_percentage);
        int rdy_low_percentage;
        bit rdy;

        if(rdy_high_percentage >= 100)
            rdy_high_percentage = 100;
        rdy_low_percentage = 100 - rdy_high_percentage;

        // infinite loop, meaning always alter the rdy value
        forever begin
            @(slave_cb);

            std::randomize(rdy) with {
                rdy dist {
                    1 := rdy_high_percentage,
                    0 := rdy_low_percentage
                };
            };
            slave_cb.rdy <= rdy;
        end
        
    endtask
    
endinterface

`endif