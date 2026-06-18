`timescale 1ns / 1ps

module crossbar_tb;

    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH   = 4;

    // Clock & Reset
    reg clk_sys;
    reg rst_n;

    // Write Address Channel (M0 only for this basic test)
    reg [ADDR_WIDTH-1:0]   m0_fab_awaddr;
    reg [ID_WIDTH-1:0]     m0_fab_awid;
    reg                    m0_fab_awvalid;
    reg [7:0]              m0_fab_awlen;
    reg [2:0]              m0_fab_awsize;
    reg [1:0]              m0_fab_awburst;
    wire                   m0_fab_awready;

    // Tie off other masters for now
    reg [ADDR_WIDTH-1:0]   m1_fab_awaddr  = 0; reg [ID_WIDTH-1:0]  m1_fab_awid = 0;   reg m1_fab_awvalid = 0;
    reg [ADDR_WIDTH-1:0]   m2_fab_awaddr  = 0; reg [ID_WIDTH-1:0]  m2_fab_awid = 0;   reg m2_fab_awvalid = 0;
    wire                   m1_fab_awready, m2_fab_awready;

    // Slave Write Address Interface
    wire [ADDR_WIDTH-1:0]  s_awaddr;
    wire [ID_WIDTH+1:0]    s_awid; 
    wire                   s_awvalid;
    reg                    s_awready;

    // Write Data Channel (M0)
    reg [DATA_WIDTH-1:0]     m0_fab_wdata;
    reg [(DATA_WIDTH/8)-1:0] m0_fab_wstrb;
    reg                      m0_fab_wvalid;
    reg                      m0_fab_wlast;
    wire                     m0_fab_wready;

    // Tie off other master data
    reg [DATA_WIDTH-1:0] m1_fab_wdata = 0; reg m1_fab_wvalid = 0; reg m1_fab_wlast = 0;
    reg [DATA_WIDTH-1:0] m2_fab_wdata = 0; reg m2_fab_wvalid = 0; reg m2_fab_wlast = 0;
    wire                 m1_fab_wready, m2_fab_wready;

    // Slave Write Data Interface
    wire [DATA_WIDTH-1:0]    s_wdata;
    wire                     s_wvalid;
    wire                     s_wlast;
    reg                      s_wready;

    // Write Response Channel
    reg [ID_WIDTH+1:0]       s_bid;
    reg                      s_bvalid;
    wire                     s_bready;
    wire [ID_WIDTH-1:0]      m0_fab_bid;
    wire                     m0_fab_bvalid;
    reg                      m0_fab_bready;

    // Clock Generation (100 MHz)
    always #5 clk_sys = ~clk_sys;

    // ========================================================================
    // DUT Instantiation
    // ========================================================================
    crossbar #(
        .W1(1), .W2(2), .W3(4),
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) DUT (
        .clk_sys(clk_sys), .rst_n(rst_n),
        
        // M0 Write Address
        .m0_fab_awaddr(m0_fab_awaddr), .m0_fab_awid(m0_fab_awid), .m0_fab_awvalid(m0_fab_awvalid),
        .m0_fab_awlen(m0_fab_awlen), .m0_fab_awsize(m0_fab_awsize), .m0_fab_awburst(m0_fab_awburst),
        .m0_fab_awready(m0_fab_awready),

        // M1/M2 Tied Off
        .m1_fab_awvalid(m1_fab_awvalid), .m1_fab_awready(m1_fab_awready),
        .m2_fab_awvalid(m2_fab_awvalid), .m2_fab_awready(m2_fab_awready),

        // Slave Write Address
        .s_awaddr(s_awaddr), .s_awid(s_awid), .s_awvalid(s_awvalid), .s_awready(s_awready),

        // M0 Write Data
        .m0_fab_wdata(m0_fab_wdata), .m0_fab_wstrb(m0_fab_wstrb), .m0_fab_wvalid(m0_fab_wvalid),
        .m0_fab_wlast(m0_fab_wlast), .m0_fab_wready(m0_fab_wready),

        // M1/M2 Tied Off
        .m1_fab_wvalid(m1_fab_wvalid), .m1_fab_wready(m1_fab_wready),
        .m2_fab_wvalid(m2_fab_wvalid), .m2_fab_wready(m2_fab_wready),

        // Slave Write Data
        .s_wdata(s_wdata), .s_wvalid(s_wvalid), .s_wlast(s_wlast), .s_wready(s_wready),

        // Response Path
        .s_bid(s_bid), .s_bvalid(s_bvalid), .s_bready(s_bready), .s_bresp(2'b00),
        .m0_fab_bid(m0_fab_bid), .m0_fab_bvalid(m0_fab_bvalid), .m0_fab_bready(m0_fab_bready)
    );

    // ========================================================================
    // Stimulus
    // ========================================================================
    initial begin
        // Initialize Signals
        clk_sys = 0;
        rst_n = 0;
        m0_fab_awaddr = 0; m0_fab_awid = 0; m0_fab_awvalid = 0;
        m0_fab_awlen = 0; m0_fab_awsize = 3'b010; m0_fab_awburst = 2'b01;
        m0_fab_wdata = 0; m0_fab_wstrb = 4'b1111; m0_fab_wvalid = 0; m0_fab_wlast = 0;
        s_awready = 0; s_wready = 0; s_bid = 0; s_bvalid = 0; m0_fab_bready = 1;

        // Power-On Reset
        #20;
        rst_n = 1;
        #10;

        $display("[TB] Starting Master 0 Write Transaction Transaction...");

        // --- STEP 1: Address Phase ---
        @(posedge clk_sys);
        m0_fab_awaddr  = 32'hA000_1000;
        m0_fab_awid    = 4'h5;          // Master 0 uses ID 5
        m0_fab_awvalid = 1'b1;
        s_awready      = 1'b1;          // Slave is ready immediately

        while (!(s_awvalid && s_awready)) begin
            @(posedge clk_sys);
        end
        // Clear Address Valid
        m0_fab_awvalid = 1'b0;
        s_awready      = 1'b0;
        $display("[TB] AW Handshake Completed. Remapped Slave ID = %h (Expected: 05)", s_awid);

        // --- STEP 2: Data Phase ---
        @(posedge clk_sys);
        m0_fab_wdata   = 32'hDEAD_BEEF;
        m0_fab_wvalid  = 1'b1;
        m0_fab_wlast   = 1'b1;          // Asserted because this is the final beat of the burst
        s_wready       = 1'b1;          // Slave signals it is ready

        @(posedge clk_sys);
        // Corrected: Monitors the slave-side interface for the final handshaking beat
        while (!(s_wvalid && s_wready && s_wlast)) begin
            @(posedge clk_sys); 
        end

        // Clear signals immediately on the clock edge AFTER the handshake completes
        m0_fab_wvalid  = 1'b0;
        m0_fab_wlast   = 1'b0;
        s_wready       = 1'b0;
        $display("[TB] W Channel Handshake Completed. Slave captured final burst data = %h", s_wdata);

        // --- STEP 3: Response Phase ---
        #20;
        @(posedge clk_sys);
        s_bid    = 6'h05;               // Slave returns the prefixed ID (00_0101)
        s_bvalid = 1'b1;

        @(posedge clk_sys);
        while (!(s_bready && m0_fab_bvalid)) @(posedge clk_sys);
        
        s_bvalid = 1'b0;
        $display("[TB] B Handshake Completed. Master 0 received response for ID = %h", m0_fab_bid);

        #50;
        $display("[TB] Test Complete.");
        $finish;
    end

endmodule