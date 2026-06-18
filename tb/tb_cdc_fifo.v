`timescale 1ns/1ns

// ============================================================================
// Test 1: Basic CDC transfer
// Test 2: Master faster than switch (FIFO fills)
// Test 3: Empty check (s_valid stays 0)
// Test 4: Fill FIFO completely
// Test 5: Reset mid transfer
// ============================================================================

module tb_cdc_fifo;

localparam DATA_WIDTH = 32;
localparam PTR_SIZE   = 4;
localparam DEPTH      = 16;

// write domain — you act as master
reg                   wr_clk;
reg                   wr_rst;    // active HIGH
reg                   wr_valid;
reg  [DATA_WIDTH-1:0] wr_data;
wire                  wr_ready;

// read domain — you act as skid buffer / switch
reg                   rd_clk;
reg                   rd_rst;    // active HIGH
wire                  rd_valid;
reg                   rd_ready;
wire [DATA_WIDTH-1:0] rd_data;

cdc_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .PTR_SIZE   (PTR_SIZE),
    .DEPTH      (DEPTH)
) dut (
    // write domain
    .wr_clk   (wr_clk),
    .wr_rst   (wr_rst),
    .wr_valid (wr_valid),
    .wr_ready (wr_ready),
    .wr_data  (wr_data),

    // read domain
    .rd_clk   (rd_clk),
    .rd_rst   (rd_rst),
    .rd_valid (rd_valid),
    .rd_ready (rd_ready),
    .rd_data  (rd_data)
);

initial wr_clk = 0;
always #5  wr_clk = ~wr_clk;   // 100MHz

initial rd_clk = 0;
always #20 rd_clk = ~rd_clk;   // 25MHz

initial begin
    $dumpfile("sim/tb_cdc_fifo.vcd");
    $dumpvars(0, tb_cdc_fifo);
end

integer i;

initial begin

    // initialise all signals
    wr_rst   = 1;     // reset ON
    rd_rst   = 1;     // reset ON
    wr_valid = 0;
    wr_data  = 0;
    rd_ready = 0;
    #40;
    wr_rst   = 0;     // reset OFF
    rd_rst   = 0;     // reset OFF
    //repeat (10) @(posedge rd_clk);  // to check setup violation
    #20;

    // ─────────────────────────────────
    // Test 1: Basic CDC transfer
    // write 5 values, switch always ready
    // verify same values come out other side
    // ─────────────────────────────────
    $display("--- Test 1: Basic CDC transfer ---");
    
    wr_valid = 1;
    for (i = 0; i < 5; i = i + 1) begin
        wr_data = i;
        #10;             // one master clock cycle
    end
    wr_valid = 0;
    #100;                // wait — CDC sync needs extra cycles
    rd_ready = 1;        // switch ready to read
    #(40*5);       //read 5 data
    rd_ready = 0;        // switch stops reading

    $display("Test 1 done");
    #20;

    // ─────────────────────────────────
    // Test 2: Master faster than switch
    // switch stops reading → FIFO fills up
    // wr_ready should drop to 0 when full
    // ─────────────────────────────────
    $display("--- Test 2: Master faster, switch slow ---");
    rd_ready = 0;        // switch stops reading
    wr_valid = 1;
    for (i = 10; i < 20; i = i + 1) begin
        wr_data = i;
        #10;
        if (!wr_ready)
            $display("t=%0t | FIFO FULL — wr_ready=0 master blocked", $time);
    end
    wr_valid = 0;
    #40;
    rd_ready = 1;        // switch resumes reading
    #300;
    $display("Test 2 done");

    // ─────────────────────────────────
    // Test 3: Empty check
    // master sends nothing
    // rd_valid must stay 0
    // ─────────────────────────────────
    $display("--- Test 3: Empty FIFO check ---");
    wr_valid = 0;
    rd_ready = 1;
    #100;
    if (!rd_valid)
        $display("t=%0t | CORRECT — rd_valid=0 FIFO empty", $time);
    else
        $display("t=%0t | ERROR   — rd_valid should be 0!", $time);
    $display("Test 3 done");

    // ─────────────────────────────────
    // Test 4: Fill FIFO completely
    // write DEPTH values with switch stopped
    // then drain everything
    // ─────────────────────────────────
    $display("--- Test 4: Fill FIFO completely ---");
    rd_ready = 0;
    wr_valid = 1;
    for (i = 100; i < 100 + DEPTH; i = i + 1) begin
        wr_data = i;
        #10;
    end
    wr_valid = 0;
    #40;
    rd_ready = 1;        // drain all
    #800;
    $display("Test 4 done");

    // ─────────────────────────────────
    // Test 5: Reset mid transfer
    // assert reset while data is in flight
    // verify clean recovery after reset
    // ─────────────────────────────────
    $display("--- Test 5: Reset mid transfer ---");
    rd_ready = 0;
    wr_valid = 1;
    wr_data  = 32'hDEAD_BEEE;
    #10;
    wr_data  = 32'hCAFE_BABE;
    #10;

    // assert reset mid transfer
    wr_rst   = 1;
    rd_rst   = 1;
    #20;

    // release reset
    wr_rst   = 0;
    rd_rst   = 0;
    wr_valid = 0;
    rd_ready = 1;
    #100;
    $display("Test 5 done");

    $display("=== All tests complete ===");
    #100;
    $finish;
end

// ─────────────────────────────────────
// Monitors
// print every write into FIFO
// print every read out of FIFO
// ─────────────────────────────────────
always @(posedge wr_clk) begin
    if (wr_valid && wr_ready)
        $display("t=%0t | WRITE wr_data=%0d (0x%08h)", $time, wr_data, wr_data);
end

always @(posedge rd_clk) begin
    if (rd_valid && rd_ready)
        $display("t=%0t | READ  rd_data=%0d (0x%08h)", $time, rd_data, rd_data);
end

endmodule