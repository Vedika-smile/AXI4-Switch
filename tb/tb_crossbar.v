`timescale 1ns/1ps

module tb_crossbar;

    // =============================================
    // 1. Global Parameters & Signals
    // =============================================
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH   = 4;
    parameter STRB_WIDTH = DATA_WIDTH / 8;

    reg clk_sys;
    reg rst_n;

    // --- Testbench Master 0 Variables ---
    reg  [ADDR_WIDTH-1:0] m0_awaddr;
    reg  [ID_WIDTH-1:0]   m0_awid;
    reg  [7:0]            m0_awlen;
    reg  [2:0]            m0_awsize;
    reg  [1:0]            m0_awburst;
    reg                   m0_awvalid;
    wire                  m0_awready;
    reg  [DATA_WIDTH-1:0] m0_wdata;
    reg  [STRB_WIDTH-1:0] m0_wstrb;
    reg                   m0_wlast;
    reg                   m0_wvalid;
    wire                  m0_wready;
    wire [ID_WIDTH-1:0]   m0_bid;
    wire                  m0_bvalid;
    wire [1:0]            m0_bresp;
    reg                   m0_bready;

    // --- Testbench Master 1 Variables ---
    reg  [ADDR_WIDTH-1:0] m1_awaddr;
    reg  [ID_WIDTH-1:0]   m1_awid;
    reg  [7:0]            m1_awlen;
    reg  [2:0]            m1_awsize;
    reg  [1:0]            m1_awburst;
    reg                   m1_awvalid;
    wire                  m1_awready;
    reg  [DATA_WIDTH-1:0] m1_wdata;
    reg  [STRB_WIDTH-1:0] m1_wstrb;
    reg                   m1_wlast;
    reg                   m1_wvalid;
    wire                  m1_wready;
    wire [ID_WIDTH-1:0]   m1_bid;
    wire                  m1_bvalid;
    wire [1:0]            m1_bresp;
    reg                   m1_bready;

    // --- Testbench Master 2 Variables ---
    reg  [ADDR_WIDTH-1:0] m2_awaddr;
    reg  [ID_WIDTH-1:0]   m2_awid;
    reg  [7:0]            m2_awlen;
    reg  [2:0]            m2_awsize;
    reg  [1:0]            m2_awburst;
    reg                   m2_awvalid;
    wire                  m2_awready;
    reg  [DATA_WIDTH-1:0] m2_wdata;
    reg  [STRB_WIDTH-1:0] m2_wstrb;
    reg                   m2_wlast;
    reg                   m2_wvalid;
    wire                  m2_wready;
    wire [ID_WIDTH-1:0]   m2_bid;
    wire                  m2_bvalid;
    wire [1:0]            m2_bresp;
    reg                   m2_bready;

    // --- Slave Interface Wires (Outputs from Crossbar) ---
    wire [ADDR_WIDTH-1:0]  s_awaddr;
    wire [ID_WIDTH+1:0]    s_awid; 
    wire                   s_awvalid;
    wire [7:0]             s_awlen;
    wire [2:0]             s_awsize;
    wire [1:0]             s_awburst;
    wire                   s_awready;
    wire [DATA_WIDTH-1:0]  s_wdata;
    wire [(DATA_WIDTH/8)-1:0] s_wstrb;
    wire                   s_wvalid;
    wire                   s_wlast;
    wire                   s_wready;
    
    // --- Driven Slave Signals (Inputs to Crossbar) ---
    reg [ID_WIDTH+1:0]     s_bid;
    reg                    s_bvalid;
    reg [1:0]              s_bresp;
    wire                   s_bready;

    // Read channel pins (Unused placeholders to keep compilation clean)
    reg [ADDR_WIDTH-1:0] m0_araddr; reg [ID_WIDTH-1:0] m0_arid; reg m0_arvalid; reg [7:0] m0_arlen; reg [2:0] m0_arsize; reg [1:0] m0_arburst; wire m0_arready;
    reg [ADDR_WIDTH-1:0] m1_araddr; reg [ID_WIDTH-1:0] m1_arid; reg m1_arvalid; reg [7:0] m1_arlen; reg [2:0] m1_arsize; reg [1:0] m1_arburst; wire m1_arready;
    reg [ADDR_WIDTH-1:0] m2_araddr; reg [ID_WIDTH-1:0] m2_arid; reg m2_arvalid; reg [7:0] m2_arlen; reg [2:0] m2_arsize; reg [1:0] m2_arburst; wire m2_arready;
    wire [ADDR_WIDTH-1:0] s_araddr; wire [ID_WIDTH+1:0] s_arid; wire s_arvalid; wire [7:0] s_arlen; wire [2:0] s_arsize; wire [1:0] s_arburst; wire s_arready;
    reg [ID_WIDTH+1:0] s_rid; reg [DATA_WIDTH-1:0] s_rdata; reg [1:0] s_rresp; reg s_rlast; reg s_rvalid; wire s_rready;
    wire [ID_WIDTH-1:0] m0_fab_rid; wire [DATA_WIDTH-1:0] m0_fab_rdata; wire [1:0] m0_fab_rresp; wire m0_fab_rlast; wire m0_fab_rvalid; reg m0_fab_rready;
    wire [ID_WIDTH-1:0] m1_fab_rid; wire [DATA_WIDTH-1:0] m1_fab_rdata; wire [1:0] m1_fab_rresp; wire m1_fab_rlast; wire m1_fab_rvalid; reg m1_fab_rready;
    wire [ID_WIDTH-1:0] m2_fab_rid; wire [DATA_WIDTH-1:0] m2_fab_rdata; wire [1:0] m2_fab_rresp; wire m2_fab_rlast; wire m2_fab_rvalid; reg m2_fab_rready;

    // =============================================
    // 2. Clock Generator
    // =============================================
    always #5 clk_sys = ~clk_sys;

    // =============================================
    // 3. DUT Instance (With Exact Port Re-Mapping)
    // =============================================
    crossbar #(
        .W1(1), .W2(2), .W3(4),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .clk_sys(clk_sys),
        .rst_n(rst_n),
        
        // --- Master 0 Ports ---
        .m0_fab_awaddr(m0_awaddr),   .m0_fab_awid(m0_awid),       .m0_fab_awvalid(m0_awvalid),
        .m0_fab_awlen(m0_awlen),     .m0_fab_awsize(m0_awsize),   .m0_fab_awburst(m0_awburst), .m0_fab_awready(m0_awready),
        .m0_fab_wdata(m0_wdata),     .m0_fab_wstrb(m0_wstrb),     .m0_fab_wvalid(m0_wvalid),   .m0_fab_wlast(m0_wlast),     .m0_fab_wready(m0_wready),
        .m0_fab_bid(m0_bid),         .m0_fab_bvalid(m0_bvalid),   .m0_fab_bresp(m0_bresp),     .m0_fab_bready(m0_bready),

        // --- Master 1 Ports ---
        .m1_fab_awaddr(m1_awaddr),   .m1_fab_awid(m1_awid),       .m1_fab_awvalid(m1_awvalid),
        .m1_fab_awlen(m1_awlen),     .m1_fab_awsize(m1_awsize),   .m1_fab_awburst(m1_awburst), .m1_fab_awready(m1_awready),
        .m1_fab_wdata(m1_wdata),     .m1_fab_wstrb(m1_wstrb),     .m1_fab_wvalid(m1_wvalid),   .m1_fab_wlast(m1_wlast),     .m1_fab_wready(m1_wready),
        .m1_fab_bid(m1_bid),         .m1_fab_bvalid(m1_bvalid),   .m1_fab_bresp(m1_bresp),     .m1_fab_bready(m1_bready),

        // --- Master 2 Ports ---
        .m2_fab_awaddr(m2_awaddr),   .m2_fab_awid(m2_awid),       .m2_fab_awvalid(m2_awvalid),
        .m2_fab_awlen(m2_awlen),     .m2_fab_awsize(m2_awsize),   .m2_fab_awburst(m2_awburst), .m2_fab_awready(m2_awready),
        .m2_fab_wdata(m2_wdata),     .m2_fab_wstrb(m2_wstrb),     .m2_fab_wvalid(m2_wvalid),   .m2_fab_wlast(m2_wlast),     .m2_fab_wready(m2_wready),
        .m2_fab_bid(m2_bid),         .m2_fab_bvalid(m2_bvalid),   .m2_fab_bresp(m2_bresp),     .m2_fab_bready(m2_bready),

        // --- Downstream Slave Ports ---
        .s_awaddr(s_awaddr),   .s_awid(s_awid),       .s_awvalid(s_awvalid), .s_awlen(s_awlen), 
        .s_awsize(s_awsize), .s_awburst(s_awburst), .s_awready(s_awready),
        .s_wdata(s_wdata),     .s_wstrb(s_wstrb),     .s_wvalid(s_wvalid),   .s_wlast(s_wlast), .s_wready(s_wready),
        .s_bid(s_bid),         .s_bvalid(s_bvalid),   .s_bresp(s_bresp),     .s_bready(s_bready),

        // --- Unused Read System Interface Connections ---
        .m0_fab_araddr(m0_araddr), .m0_fab_arid(m0_arid), .m0_fab_arvalid(m0_arvalid), .m0_fab_arlen(m0_arlen),
        .m0_fab_arsize(m0_arsize), .m0_fab_arburst(m0_arburst), .m0_fab_arready(m0_arready),
        .m1_fab_araddr(m1_araddr), .m1_fab_arid(m1_arid), .m1_fab_arvalid(m1_arvalid), .m1_fab_arlen(m1_arlen), 
        .m1_fab_arsize(m1_arsize), .m1_fab_arburst(m1_arburst), .m1_fab_arready(m1_arready),
        .m2_fab_araddr(m2_araddr), .m2_fab_arid(m2_arid), .m2_fab_arvalid(m2_arvalid), .m2_fab_arlen(m2_arlen), 
        .m2_fab_arsize(m2_arsize), .m2_fab_arburst(m2_arburst), .m2_fab_arready(m2_arready),
        .s_araddr(s_araddr), .s_arid(s_arid), .s_arvalid(s_arvalid), .s_arlen(s_arlen), 
        .s_arsize(s_arsize), .s_arburst(s_arburst), .s_arready(s_arready),

        //Read data
        .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
        .m0_fab_rid(m0_fab_rid), .m0_fab_rdata(m0_fab_rdata), .m0_fab_rresp(m0_fab_rresp), 
        .m0_fab_rlast(m0_fab_rlast), .m0_fab_rvalid(m0_fab_rvalid), .m0_fab_rready(m0_fab_rready),
        .m1_fab_rid(m1_fab_rid), .m1_fab_rdata(m1_fab_rdata), .m1_fab_rresp(m1_fab_rresp), 
        .m1_fab_rlast(m1_fab_rlast), .m1_fab_rvalid(m1_fab_rvalid), .m1_fab_rready(m1_fab_rready),
        .m2_fab_rid(m2_fab_rid), .m2_fab_rdata(m2_fab_rdata), .m2_fab_rresp(m2_fab_rresp), 
        .m2_fab_rlast(m2_fab_rlast), .m2_fab_rvalid(m2_fab_rvalid), .m2_fab_rready(m2_fab_rready)
    );

    // =============================================
    // 4. Reusable Master Drivers
    // =============================================
    task m0_write(input [ADDR_WIDTH-1:0] addr, input [ID_WIDTH-1:0] id, input [7:0] len, input [DATA_WIDTH-1:0] data0);
        integer b;
        begin
            m0_awaddr = addr;
            m0_awid = id; 
            m0_awlen = len; 
            m0_awsize = 3'b010;  //4 bytes
            m0_awburst = 2'b01;   //INCR
            m0_awvalid = 1;
            @(posedge clk_sys); 
            while (!m0_awready) @(posedge clk_sys); 
            m0_awvalid = 0;
            //W phase- len+1 beats
            for (b = 0; b <= len; b = b + 1) begin
                m0_wdata = data0 + b; 
                m0_wstrb = {STRB_WIDTH{1'b1}}; 
                m0_wlast = (b == len); 
                m0_wvalid = 1;
                @(posedge clk_sys); 
                while (!m0_wready) @(posedge clk_sys);
            end
            //B phase
            m0_wvalid = 0; 
            m0_bready = 1;
            while (!m0_bvalid) @(posedge clk_sys);
            $display("t=%0t | M0 WRITE done bid=%0d bresp=%0d", $time, m0_bid, m0_bresp);
            @(posedge clk_sys); 
            m0_bready = 0;
        end
    endtask

    task m1_write(input [ADDR_WIDTH-1:0] addr, input [ID_WIDTH-1:0] id, input [7:0] len, input [DATA_WIDTH-1:0] data0);
        integer b;
        begin
            m1_awaddr = addr; m1_awid = id; m1_awlen = len; m1_awsize = 3'b010; m1_awburst = 2'b01; m1_awvalid = 1;
            @(posedge clk_sys); 
            while (!m1_awready) @(posedge clk_sys); 
            m1_awvalid = 0;
            for (b = 0; b <= len; b = b + 1) begin
                m1_wdata = data0 + b;
                m1_wstrb = {STRB_WIDTH{1'b1}}; 
                m1_wlast = (b == len); 
                m1_wvalid = 1;
                @(posedge clk_sys); 
                while (!m1_wready) @(posedge clk_sys);
            end
            m1_wvalid = 0; m1_bready = 1;
            while (!m1_bvalid) @(posedge clk_sys);
            $display("t=%0t | M1 WRITE done bid=%0d bresp=%0d", $time, m1_bid, m1_bresp);
            @(posedge clk_sys); m1_bready = 0;
        end
    endtask

    task m2_write(input [ADDR_WIDTH-1:0] addr, input [ID_WIDTH-1:0] id, input [7:0] len, input [DATA_WIDTH-1:0] data0);
        integer b;
        begin
            m2_awaddr = addr; m2_awid = id; m2_awlen = len; m2_awsize = 3'b010; m2_awburst = 2'b01; m2_awvalid = 1;
            @(posedge clk_sys); 
            while (!m2_awready) @(posedge clk_sys); 
            m2_awvalid = 0;
            for (b = 0; b <= len; b = b + 1) begin
                m2_wdata = data0 + b; 
                m2_wstrb = {STRB_WIDTH{1'b1}}; 
                m2_wlast = (b == len); 
                m2_wvalid = 1;
                @(posedge clk_sys); 
                while (!m2_wready) @(posedge clk_sys);
            end
            m2_wvalid = 0; m2_bready = 1;
            while (!m2_bvalid) @(posedge clk_sys);
            $display("t=%0t | M2 WRITE done bid=%0d bresp=%0d", $time, m2_bid, m2_bresp);
            @(posedge clk_sys); m2_bready = 0;
        end
    endtask

    task m0_write_bhold(input [ADDR_WIDTH-1:0] addr,
                        input [ID_WIDTH-1:0] id,
                        input [7:0] len,
                        input [DATA_WIDTH-1:0] data0);
        integer b;
        begin
            // AW phase
            m0_awaddr = addr; m0_awid = id; m0_awlen = len;
            m0_awsize = 3'b010; m0_awburst = 2'b01; m0_awvalid = 1;
            @(posedge clk_sys);
            while (!m0_awready) @(posedge clk_sys);
            m0_awvalid = 0;

            // W phase
            for (b = 0; b <= len; b = b + 1) begin
                m0_wdata = data0 + b; m0_wstrb = {STRB_WIDTH{1'b1}};
                m0_wlast = (b == len); m0_wvalid = 1;
                @(posedge clk_sys);
                while (!m0_wready) @(posedge clk_sys);
            end
            m0_wvalid = 0;

            // B phase - hold bready LOW for 20 cycles
            m0_bready = 0;
            $display("t=%0t | Holding bready LOW", $time);
            repeat(20) @(posedge clk_sys);
            $display("t=%0t | Releasing bready", $time);
            m0_bready = 1;
            @(posedge clk_sys);   
            while (!m0_bvalid) @(posedge clk_sys);
            $display("t=%0t | M0 BHOLD WRITE done bid=%0d bresp=%0d",
                    $time, m0_bid, m0_bresp);
            @(posedge clk_sys);
            m0_bready = 0;
        end
    endtask


    task m0_write_delayed(input [ADDR_WIDTH-1:0] addr,
                      input [ID_WIDTH-1:0]   id,
                      input [7:0]            len,
                      input [DATA_WIDTH-1:0] data0);
    integer b;
    begin
        // AW phase fires immediately
        m0_awaddr  = addr;
        m0_awid    = id;
        m0_awlen   = len;
        m0_awsize  = 3'b010;
        m0_awburst = 2'b01;
        m0_awvalid = 1;
        @(posedge clk_sys);
        while (!m0_awready) @(posedge clk_sys);
        m0_awvalid = 0;

        // W phase deliberately delayed by 10 cycles
        $display("t=%0t | M0 AW done, holding W for 10 cycles", $time);
        repeat(10) @(posedge clk_sys);
        $display("t=%0t | M0 W phase starting now", $time);

        // W phase
        for (b = 0; b <= len; b = b + 1) begin
            m0_wdata  = data0 + b;
            m0_wstrb  = {STRB_WIDTH{1'b1}};
            m0_wlast  = (b == len);
            m0_wvalid = 1;
            @(posedge clk_sys);
            while (!m0_wready) @(posedge clk_sys);
        end

        // B phase
        m0_wvalid = 0;
        m0_bready = 1;
        while (!m0_bvalid) @(posedge clk_sys);
        $display("t=%0t | M0 DELAYED WRITE done bid=%0d bresp=%0d",
                  $time, m0_bid, m0_bresp);
        @(posedge clk_sys);
        m0_bready = 0;
    end
    endtask

    // =============================================
    // 5. Slave BFM (Responsive Interleaved Queue)
    // =============================================
    // reg [ID_WIDTH+1:0] aw_q_id [0:3];
    // reg [1:0]          aw_wp, aw_rp;
    // assign s_awready = 1'b1;
    // assign s_wready  = 1'b1;

    // always @(posedge clk_sys or negedge rst_n) begin
    //     if (!rst_n) begin
    //         aw_wp    <= 0;
    //         aw_rp    <= 0;
    //         s_bvalid <= 0; 
    //         s_bid    <= 0; 
    //         s_bresp  <= 2'b00;
    //     end else begin
    //         if (s_awvalid && s_awready) begin
    //             aw_q_id[aw_wp] <= s_awid;
    //             aw_wp          <= aw_wp + 1;
    //         end

    //         // if (s_wvalid && s_wready && s_wlast) begin
    //         //     s_bvalid <= 1'b1;
    //         //     s_bresp  <= 2'b00;  //OKAY
    //         //     if (aw_wp == aw_rp && s_awvalid) begin
    //         //         s_bid <= s_awid;
    //         //     end else begin
    //         //         s_bid <= aw_q_id[aw_rp];
    //         //     end
    //         //     aw_rp <= aw_rp + 1;
    //         // end else if (s_bvalid && s_bready) begin
    //         //     s_bvalid <= 1'b0;
    //         // end
    //         if (s_wvalid && s_wready && s_wlast && !s_bvalid) begin
    //             s_bvalid <= 1'b1;
    //             s_bid    <= aw_q_id[aw_rp];
    //             s_bresp  <= 2'b00;
    //             aw_rp    <= aw_rp + 1;
    //         end else if (s_bvalid && s_bready) begin
    //             s_bvalid <= 1'b0;
    //         end
    //     end
    // end
// Declarations
    reg [ID_WIDTH+1:0] aw_q_id [0:3];
    reg [1:0]          aw_wp, aw_rp;
    reg [ID_WIDTH+1:0] b_q_id  [0:3];
    reg [1:0]          b_wp, b_rp;

    assign s_awready = 1'b1;
    assign s_wready  = 1'b1;

    // ONE single always block - delete the old one completely
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            aw_wp <= 0; aw_rp <= 0;
            b_wp  <= 0; b_rp  <= 0;
            s_bvalid <= 0; s_bid <= 0; s_bresp <= 2'b00;
        end else begin
            if (s_awvalid && s_awready) begin
                aw_q_id[aw_wp] <= s_awid;
                aw_wp          <= aw_wp + 1;
            end
            if (s_wvalid && s_wready && s_wlast) begin
                b_q_id[b_wp] <= aw_q_id[aw_rp];
                b_wp         <= b_wp + 1;
                aw_rp        <= aw_rp + 1;
            end
            if (s_bvalid && s_bready) begin
                s_bvalid <= 1'b0;
            end else if (!s_bvalid && (b_rp != b_wp)) begin
                s_bvalid <= 1'b1;
                s_bid    <= b_q_id[b_rp];
                s_bresp  <= 2'b00;
                b_rp     <= b_rp + 1;
            end
        end
    end
    // =============================================
    // 6. Main Test Stimulus Block (Unified Parallel R/W)
    // =============================================
    initial begin
        // --- 1. Reset & Initialize Everything at t=0 ---
        clk_sys = 0; rst_n = 0;
        
        m0_awaddr = 0; m0_awid = 0; m0_awlen = 0; m0_awsize = 0; m0_awburst = 0; m0_awvalid = 0; m0_wdata = 0; m0_wstrb = 0; m0_wlast = 0; m0_wvalid = 0; m0_bready = 0;
        m1_awaddr = 0; m1_awid = 0; m1_awlen = 0; m1_awsize = 0; m1_awburst = 0; m1_awvalid = 0; m1_wdata = 0; m1_wstrb = 0; m1_wlast = 0; m1_wvalid = 0; m1_bready = 0;
        m2_awaddr = 0; m2_awid = 0; m2_awlen = 0; m2_awsize = 0; m2_awburst = 0; m2_awvalid = 0; m2_wdata = 0; m2_wstrb = 0; m2_wlast = 0; m2_wvalid = 0; m2_bready = 0;
        
        m0_araddr = 0; m0_arid = 0; m0_arvalid = 0; m0_arlen = 0; m0_arsize = 0; m0_arburst = 0; m0_fab_rready = 0;
        m1_araddr = 0; m1_arid = 0; m1_arvalid = 0; m1_arlen = 0; m1_arsize = 0; m1_arburst = 0; m1_fab_rready = 0;
        m2_araddr = 0; m2_arid = 0; m2_arvalid = 0; m2_arlen = 0; m2_arsize = 0; m2_arburst = 0; m2_fab_rready = 0;
        s_rid = 0; s_rdata = 0; s_rresp = 0; s_rlast = 0; s_rvalid = 0;

        // --- 2. Safe Power-On Reset Sequence ---
        #40;
        @(negedge clk_sys);
        rst_n = 1; 
        #20; // Let the system settle
        
        $display("--- Starting Phase 1: Write Traffic ---");
        fork
            // m0_write(32'h1000, 4'd1, 8'd3, 32'hA000); 
            // begin
            //     #20;
            //     m1_write(32'h2000, 4'd2, 8'd0, 32'hB000); 
            // end
            // m2_write(32'h3000, 4'd3, 8'd0, 32'hC000);

            // m0_write(32'h1000, 4'd1, 8'd3, 32'hA000);
            // m1_write(32'h2000, 4'd2, 8'd0, 32'hB000);
            // m2_write(32'h3000, 4'd3, 8'd0, 32'hC000);

            // $display("--- Test: B channel backpressure ---");

            // m0_write_bhold(32'h1000, 4'd1, 8'd3, 32'hA000);
            // begin
            //     repeat(3) @(posedge clk_sys);
            //     m1_write(32'h2000, 4'd2, 8'd0, 32'hB000);
            // end

            // $display("--- Test: Long burst starvation ---");

            // m0_write(32'h1000, 4'd1, 8'd15, 32'hA000); // 16 beats
            // begin
            //     repeat(2) @(posedge clk_sys);
            //     m1_write(32'h2000, 4'd2, 8'd0, 32'hB000);
            //     m1_write(32'h2010, 4'd2, 8'd0, 32'hB100);
            //     m1_write(32'h2020, 4'd2, 8'd0, 32'hB200);
            // end
            // begin
            //     repeat(2) @(posedge clk_sys);
            //     m2_write(32'h3000, 4'd3, 8'd0, 32'hC000);
            //     m2_write(32'h3010, 4'd3, 8'd0, 32'hC100);
            // end

            $display("--- Test: Delayed W channel ---");
            m0_write_delayed(32'h1000, 4'd1, 8'd3, 32'hA000);
            begin
                repeat(2) @(posedge clk_sys);
                m1_write(32'h2000, 4'd2, 8'd0, 32'hB000);
            end

            
        join // The simulation WILL wait here until ALL 3 writes are 100% finished

       

        // $display("--- Test: Back to back same master ---");
        // m0_write(32'h1000, 4'd1, 8'd3, 32'hA000);
        // m0_write(32'h1010, 4'd1, 8'd3, 32'hA100);
        // m0_write(32'h1020, 4'd1, 8'd3, 32'hA200);


        #100; // Let the bus settle
        
        $display("--- Starting Phase 2: Read Traffic ---");
        // fork
        //     m0_read(32'h5000, 4'd1, 8'd3);
        //     begin
        //         @(posedge clk_sys);
        //         m1_read(32'h6000, 4'd2, 8'd0);
        //     end
        //     begin
        //         @(posedge clk_sys);
        //         @(posedge clk_sys);
        //         m2_read(32'h7000, 4'd3, 8'd0);
        //     end
        // join
        // $display("--- Test: Read backpressure ---");
        // fork
        //     m0_read_bpressure(32'h5000, 4'd1, 8'd3);
        //     begin
        //         @(posedge clk_sys);
        //         m1_read(32'h6000, 4'd2, 8'd0);
        //     end
        //     begin
        //         @(posedge clk_sys);
        //         @(posedge clk_sys);
        //         m2_read(32'h7000, 4'd3, 8'd0);
        //     end
        // join
        // $display("--- Test: Reset mid-transaction ---");
        // fork
        //     m0_write(32'h1000, 4'd1, 8'd7, 32'hA000); // long burst, 8 beats
        //     begin
        //         repeat(3) @(posedge clk_sys); // wait 3 beats into M0's burst
        //         $display("t=%0t | Asserting reset mid-burst!", $time);
        //         rst_n = 0;
        //         repeat(4) @(posedge clk_sys);
        //         rst_n = 1;
        //         $display("t=%0t | Reset released", $time);
        //     end
        // join

        // #50;
        // $display("t=%0t | Post-reset clean transaction", $time);
        // m0_write(32'h1000, 4'd1, 8'd0, 32'hA000);
        // $display("t=%0t | Post-reset write OK", $time);
        $display("--- Test: Reset mid-transaction ---");
        fork
            begin : write_thread
                m0_write(32'h1000, 4'd1, 8'd7, 32'hA000);
            end
            begin : reset_thread
                // Wait until a few W beats are visible
                repeat(8) @(posedge clk_sys);
                $display("t=%0t | Asserting reset mid-burst!", $time);
                rst_n = 0;
                // Kill the stuck write thread
                disable write_thread;
            end
        join

        // Clean up master signals after aborted transaction
        m0_awvalid = 0; m0_wvalid = 0; m0_wlast = 0; m0_bready = 0;
        m1_awvalid = 0; m1_wvalid = 0;
        m2_awvalid = 0; m2_wvalid = 0;

        repeat(4) @(posedge clk_sys);
        rst_n = 1;
        $display("t=%0t | Reset released", $time);
        repeat(4) @(posedge clk_sys); // let pipeline flush

        // Post-reset clean transaction
        $display("t=%0t | Post-reset clean transaction", $time);
        m0_write(32'h1000, 4'd1, 8'd0, 32'hA000);
        $display("t=%0t | Post-reset write OK", $time);

        #100;
        $display("All tests finished cleanly!");
        $finish;
    end

    // always @(posedge clk_sys) begin
    // $display("t=%0t | awvalid: M0=%b M1=%b M2=%b awready: M0=%b M1=%b M2=%b",
    //           $time,
    //           m0_awvalid, m1_awvalid, m2_awvalid,
    //           m0_awready, m1_awready, m2_awready);
    // end 

    // //always block for holding bready   
    // always @(posedge clk_sys) begin
    // if (s_bvalid)
    //     $display("t=%0t | s_bvalid=%b s_bready=%b s_bid=%0d m0_bvalid=%b m0_bready=%b",
    //               $time, s_bvalid, s_bready, s_bid, m0_bvalid, m0_bready);
    // end

    // =============================================
    // 7. Monitor - Content Integrity Checker
    // =============================================
    always @(posedge clk_sys) begin
        if (s_wvalid && s_wready) begin
            if (s_wdata[15:12] == 4'hA)
                $display("t=%0t | s_wdata=0x%08h <- M0 beat", $time, s_wdata);
            else if (s_wdata[15:12] == 4'hB)
                $display("t=%0t | s_wdata=0x%08h <- M1 beat", $time, s_wdata);
            else if (s_wdata[15:12] == 4'hC)
                $display("t=%0t | s_wdata=0x%08h <- M2 beat", $time, s_wdata);
        end
    end

    //==============================================
    // read master 
    //=============================================


task m0_read(input [ADDR_WIDTH-1:0] addr,
            input [ID_WIDTH-1:0]   id,
            input [7:0]  len);
    reg handshake_done;
    begin
        m0_araddr  = addr;
        m0_arid    = id;
        m0_arlen   = len;
        m0_arsize  = 3'b010;
        m0_arburst = 2'b01;
        m0_arvalid = 1;
        handshake_done = 0;

        // Clean combinational handshake evaluation
        while (!handshake_done) begin
            if (m0_arready) begin
                @(posedge clk_sys); // Handshake safely consumed here
                handshake_done = 1;
            end else begin
                @(posedge clk_sys); // Wait if the channel is busy
            end
        end
        m0_arvalid = 0;

        m0_fab_rready = 1;
        forever begin
            @(posedge clk_sys);
            if (m0_fab_rvalid) begin
                $display("t=%0t | M0 READ rid=%0d rdata=0x%08h rlast=%b",
                           $time, m0_fab_rid, m0_fab_rdata, m0_fab_rlast);
                if (m0_fab_rlast) begin
                    m0_fab_rready = 0;
                    disable m0_read;   // exit task safely
                end
            end
        end
    end
endtask

task m1_read(input [ADDR_WIDTH-1:0] addr,
            input [ID_WIDTH-1:0]   id,
            input [7:0]  len);
    reg handshake_done;
    begin
        m1_araddr  = addr;
        m1_arid    = id;
        m1_arlen   = len;
        m1_arsize  = 3'b010;
        m1_arburst = 2'b01;
        m1_arvalid = 1;
        handshake_done = 0;

        while (!handshake_done) begin
            if (m1_arready) begin
                @(posedge clk_sys);
                handshake_done = 1;
            end else begin
                @(posedge clk_sys);
            end
        end
        m1_arvalid = 0;

        m1_fab_rready = 1;
        forever begin
            @(posedge clk_sys);
            if (m1_fab_rvalid) begin
                $display("t=%0t | M1 READ rid=%0d rdata=0x%08h rlast=%b",
                           $time, m1_fab_rid, m1_fab_rdata, m1_fab_rlast);
                if (m1_fab_rlast) begin
                    m1_fab_rready = 0;
                    disable m1_read;   
                end
            end
        end
    end
endtask

task m2_read(input [ADDR_WIDTH-1:0] addr,
            input [ID_WIDTH-1:0]   id,
            input [7:0]  len);
    reg handshake_done;
    begin
        m2_araddr  = addr;
        m2_arid    = id;
        m2_arlen   = len;
        m2_arsize  = 3'b010;
        m2_arburst = 2'b01;
        m2_arvalid = 1;
        handshake_done = 0;

        while (!handshake_done) begin
            if (m2_arready) begin
                @(posedge clk_sys);
                handshake_done = 1;
            end else begin
                @(posedge clk_sys);
            end
        end
        m2_arvalid = 0;

        m2_fab_rready = 1;
        forever begin
            @(posedge clk_sys);
            if (m2_fab_rvalid) begin
                $display("t=%0t | M2 READ rid=%0d rdata=0x%08h rlast=%b",
                           $time, m2_fab_rid, m2_fab_rdata, m2_fab_rlast);
                if (m2_fab_rlast) begin
                    m2_fab_rready = 0;
                    disable m2_read;   
                end
            end
        end
    end
endtask

//===============================
// bckpressure 
//==============================
task m0_read_bpressure(input [ADDR_WIDTH-1:0] addr,
                       input [ID_WIDTH-1:0] id,
                       input [7:0] len);
    reg handshake_done;
    integer beat_count;
    begin
        m0_araddr = addr; m0_arid = id; m0_arlen = len;
        m0_arsize = 3'b010; m0_arburst = 2'b01; m0_arvalid = 1;
        handshake_done = 0;
        while (!handshake_done) begin
            if (m0_arready) begin
                @(posedge clk_sys); handshake_done = 1;
            end else @(posedge clk_sys);
        end
        m0_arvalid = 0;

        beat_count = 0;
        m0_fab_rready = 1;
        forever begin
            @(posedge clk_sys);
            if (m0_fab_rvalid && m0_fab_rready) begin
                $display("t=%0t | M0 BP READ rid=%0d rdata=0x%08h rlast=%b",
                          $time, m0_fab_rid, m0_fab_rdata, m0_fab_rlast);
                beat_count = beat_count + 1;
                
                // After beat 2, hold rready low for 10 cycles
                if (beat_count == 2) begin
                    m0_fab_rready = 0;
                    repeat(10) @(posedge clk_sys);
                    m0_fab_rready = 1;
                end
                
                if (m0_fab_rlast) begin
                    m0_fab_rready = 0;
                    disable m0_read_bpressure;
                end
            end
        end
    end
endtask

//====================================
//8. Read-side Slave BFM
// Queues incoming AR requests, responds on R
//===================================
    reg [ID_WIDTH+1:0]   ar_q_id   [0:3];
    reg [ADDR_WIDTH-1:0] ar_q_addr [0:3];
    reg [7:0] ar_q_len  [0:3];
    reg [1:0] ar_wp, ar_rp;

    assign s_arready = 1'b1;   // always accept AR (queue depth 4)
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            ar_wp <= 0;
            ar_rp <= 0;
        end else if (s_arvalid && s_arready) begin
            ar_q_id[ar_wp]   <= s_arid;
            ar_q_addr[ar_wp] <= s_araddr;
            ar_q_len[ar_wp]  <= s_arlen;
            ar_wp            <= ar_wp + 1;
        end
    end

    reg [7:0] r_beat;
    reg       r_active;

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            s_rvalid <= 0;
            r_active <= 0;
            r_beat   <= 0;
        end else begin
            if (!r_active && (ar_rp != ar_wp)) begin
                // start responding to next queued AR
                r_active <= 1;
                r_beat   <= 0;
                s_rvalid <= 1;
                s_rid    <= ar_q_id[ar_rp];
                s_rdata  <= ar_q_addr[ar_rp];      // data = address pattern
                s_rresp  <= 2'b00;
                s_rlast  <= (ar_q_len[ar_rp] == 0);
            end else if (s_rvalid && s_rready) begin
            if (s_rlast) begin
                r_active <= 0;
                s_rvalid <= 0;
                ar_rp    <= ar_rp + 1;
            end else begin
                r_beat   <= r_beat + 1;
                s_rdata  <= s_rdata + 4;
                s_rlast  <= (r_beat + 1 == ar_q_len[ar_rp]);
            end
        end
    end
    end

     // =============================================
    // Monitor — Read channel integrity checker
    // Confirms RID-based routing: each master's
    // returned rdata must match the address IT
    // requested, not another master's address.
    // =============================================
    always @(posedge clk_sys) begin
        if (s_rvalid && s_rready) begin
            $display("t=%0t | s_rid=%0d s_rdata=0x%08h s_rlast=%b",
                    $time, s_rid, s_rdata, s_rlast);
        end
    end

    // Per-master view — confirms r_demux actually
    // delivered the beat to the correct master port,
    // not just that the slave produced it correctly
    always @(posedge clk_sys) begin
        if (m0_fab_rvalid && m0_fab_rready)
            $display("t=%0t | M0 received rid=%0d rdata=0x%08h rlast=%b",
                    $time, m0_fab_rid, m0_fab_rdata, m0_fab_rlast);
        if (m1_fab_rvalid && m1_fab_rready)
            $display("t=%0t | M1 received rid=%0d rdata=0x%08h rlast=%b",
                    $time, m1_fab_rid, m1_fab_rdata, m1_fab_rlast);
        if (m2_fab_rvalid && m2_fab_rready)
            $display("t=%0t | M2 received rid=%0d rdata=0x%08h rlast=%b",
                    $time, m2_fab_rid, m2_fab_rdata, m2_fab_rlast);
    end

endmodule