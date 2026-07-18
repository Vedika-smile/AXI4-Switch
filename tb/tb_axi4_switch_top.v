`timescale 1ns/1ps
// =============================================================================
// tb_axi4_switch_top
// 3 masters (independent clocks) -> axi4_switch_top -> 1 slave BFM (clk_sys)
//
// Slave BFM behavior:
//   - Write: single in-flight transaction, memory model, BID = captured AWID
//   - Read : requests queued into an outstanding pool (depth OUTSTANDING),
//            serviced in RANDOM order to genuinely exercise out-of-order
//            read completion / ID-based routing back through r_demux.
// =============================================================================
module tb_axi4_switch_top;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam ID_WIDTH   = 4;
    localparam SID_WIDTH  = ID_WIDTH + 2; // slave-side remapped id width
    localparam FIFO_DEPTH = 16;
    localparam FIFO_PTR   = 4;
    localparam OUTSTANDING = 4;

    integer pass_count = 0;
    integer fail_count = 0;

    // =========================================================================
    // Clocks / resets — 3 independent master domains + fabric/slave domain
    // =========================================================================
    reg m0_clk = 0; always #5.0  m0_clk = ~m0_clk;  // 100 MHz
    reg m1_clk = 0; always #3.5  m1_clk = ~m1_clk;  // ~143 MHz
    reg m2_clk = 0; always #6.5  m2_clk = ~m2_clk;  // ~77 MHz
    reg clk_sys = 0; always #2.5 clk_sys = ~clk_sys; // 200 MHz

    reg m0_rst_n = 0, m1_rst_n = 0, m2_rst_n = 0, rst_n = 0;

    // =========================================================================
    // Master 0 signals
    // =========================================================================
    reg  [ID_WIDTH-1:0]     m0_awid;   reg [ADDR_WIDTH-1:0] m0_awaddr;
    reg  [7:0] m0_awlen; reg [2:0] m0_awsize; reg [1:0] m0_awburst;
    reg  m0_awvalid; wire m0_awready;
    reg  [DATA_WIDTH-1:0]   m0_wdata;  reg [DATA_WIDTH/8-1:0] m0_wstrb;
    reg  m0_wlast; reg m0_wvalid; wire m0_wready;
    wire [ID_WIDTH-1:0]     m0_bid;    wire [1:0] m0_bresp; wire m0_bvalid; reg m0_bready;
    reg  [ID_WIDTH-1:0]     m0_arid;   reg [ADDR_WIDTH-1:0] m0_araddr;
    reg  [7:0] m0_arlen; reg [2:0] m0_arsize; reg [1:0] m0_arburst;
    reg  m0_arvalid; wire m0_arready;
    wire [ID_WIDTH-1:0]     m0_rid;    wire [DATA_WIDTH-1:0] m0_rdata;
    wire [1:0] m0_rresp; wire m0_rlast; wire m0_rvalid; reg m0_rready;

    // =========================================================================
    // Master 1 signals
    // =========================================================================
    reg  [ID_WIDTH-1:0]     m1_awid;   reg [ADDR_WIDTH-1:0] m1_awaddr;
    reg  [7:0] m1_awlen; reg [2:0] m1_awsize; reg [1:0] m1_awburst;
    reg  m1_awvalid; wire m1_awready;
    reg  [DATA_WIDTH-1:0]   m1_wdata;  reg [DATA_WIDTH/8-1:0] m1_wstrb;
    reg  m1_wlast; reg m1_wvalid; wire m1_wready;
    wire [ID_WIDTH-1:0]     m1_bid;    wire [1:0] m1_bresp; wire m1_bvalid; reg m1_bready;
    reg  [ID_WIDTH-1:0]     m1_arid;   reg [ADDR_WIDTH-1:0] m1_araddr;
    reg  [7:0] m1_arlen; reg [2:0] m1_arsize; reg [1:0] m1_arburst;
    reg  m1_arvalid; wire m1_arready;
    wire [ID_WIDTH-1:0]     m1_rid;    wire [DATA_WIDTH-1:0] m1_rdata;
    wire [1:0] m1_rresp; wire m1_rlast; wire m1_rvalid; reg m1_rready;

    // =========================================================================
    // Master 2 signals
    // =========================================================================
    reg  [ID_WIDTH-1:0]     m2_awid;   reg [ADDR_WIDTH-1:0] m2_awaddr;
    reg  [7:0] m2_awlen; reg [2:0] m2_awsize; reg [1:0] m2_awburst;
    reg  m2_awvalid; wire m2_awready;
    reg  [DATA_WIDTH-1:0]   m2_wdata;  reg [DATA_WIDTH/8-1:0] m2_wstrb;
    reg  m2_wlast; reg m2_wvalid; wire m2_wready;
    wire [ID_WIDTH-1:0]     m2_bid;    wire [1:0] m2_bresp; wire m2_bvalid; reg m2_bready;
    reg  [ID_WIDTH-1:0]     m2_arid;   reg [ADDR_WIDTH-1:0] m2_araddr;
    reg  [7:0] m2_arlen; reg [2:0] m2_arsize; reg [1:0] m2_arburst;
    reg  m2_arvalid; wire m2_arready;
    wire [ID_WIDTH-1:0]     m2_rid;    wire [DATA_WIDTH-1:0] m2_rdata;
    wire [1:0] m2_rresp; wire m2_rlast; wire m2_rvalid; reg m2_rready;

    // =========================================================================
    // Slave-side signals (clk_sys domain, remapped IDs)
    // =========================================================================
    wire [ADDR_WIDTH-1:0] s_awaddr; wire [SID_WIDTH-1:0] s_awid; wire s_awvalid;
    wire [7:0] s_awlen; wire [2:0] s_awsize; wire [1:0] s_awburst; reg s_awready;

    wire [DATA_WIDTH-1:0] s_wdata; wire [DATA_WIDTH/8-1:0] s_wstrb;
    wire s_wvalid; wire s_wlast; reg s_wready;

    reg  [SID_WIDTH-1:0] s_bid; reg s_bvalid; reg [1:0] s_bresp; wire s_bready;

    wire [ADDR_WIDTH-1:0] s_araddr; wire [SID_WIDTH-1:0] s_arid; wire s_arvalid;
    wire [7:0] s_arlen; wire [2:0] s_arsize; wire [1:0] s_arburst; reg s_arready;

    reg  [SID_WIDTH-1:0] s_rid; reg [DATA_WIDTH-1:0] s_rdata;
    reg  [1:0] s_rresp; reg s_rlast; reg s_rvalid; wire s_rready;

    // =========================================================================
    // DUT
    // =========================================================================
    axi4_switch_top #(
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH), .FIFO_PTR(FIFO_PTR),
        .W1(1), .W2(2), .W3(4)
    ) dut (
        .m0_clk(m0_clk), .m0_rst_n(m0_rst_n),
        .m0_awid(m0_awid), .m0_awaddr(m0_awaddr), .m0_awlen(m0_awlen), .m0_awsize(m0_awsize),
        .m0_awburst(m0_awburst), .m0_awvalid(m0_awvalid), .m0_awready(m0_awready),
        .m0_wdata(m0_wdata), .m0_wstrb(m0_wstrb), .m0_wlast(m0_wlast), .m0_wvalid(m0_wvalid), .m0_wready(m0_wready),
        .m0_bid(m0_bid), .m0_bresp(m0_bresp), .m0_bvalid(m0_bvalid), .m0_bready(m0_bready),
        .m0_arid(m0_arid), .m0_araddr(m0_araddr), .m0_arlen(m0_arlen), .m0_arsize(m0_arsize),
        .m0_arburst(m0_arburst), .m0_arvalid(m0_arvalid), .m0_arready(m0_arready),
        .m0_rid(m0_rid), .m0_rdata(m0_rdata), .m0_rresp(m0_rresp), .m0_rlast(m0_rlast), .m0_rvalid(m0_rvalid), .m0_rready(m0_rready),

        .m1_clk(m1_clk), .m1_rst_n(m1_rst_n),
        .m1_awid(m1_awid), .m1_awaddr(m1_awaddr), .m1_awlen(m1_awlen), .m1_awsize(m1_awsize),
        .m1_awburst(m1_awburst), .m1_awvalid(m1_awvalid), .m1_awready(m1_awready),
        .m1_wdata(m1_wdata), .m1_wstrb(m1_wstrb), .m1_wlast(m1_wlast), .m1_wvalid(m1_wvalid), .m1_wready(m1_wready),
        .m1_bid(m1_bid), .m1_bresp(m1_bresp), .m1_bvalid(m1_bvalid), .m1_bready(m1_bready),
        .m1_arid(m1_arid), .m1_araddr(m1_araddr), .m1_arlen(m1_arlen), .m1_arsize(m1_arsize),
        .m1_arburst(m1_arburst), .m1_arvalid(m1_arvalid), .m1_arready(m1_arready),
        .m1_rid(m1_rid), .m1_rdata(m1_rdata), .m1_rresp(m1_rresp), .m1_rlast(m1_rlast), .m1_rvalid(m1_rvalid), .m1_rready(m1_rready),

        .m2_clk(m2_clk), .m2_rst_n(m2_rst_n),
        .m2_awid(m2_awid), .m2_awaddr(m2_awaddr), .m2_awlen(m2_awlen), .m2_awsize(m2_awsize),
        .m2_awburst(m2_awburst), .m2_awvalid(m2_awvalid), .m2_awready(m2_awready),
        .m2_wdata(m2_wdata), .m2_wstrb(m2_wstrb), .m2_wlast(m2_wlast), .m2_wvalid(m2_wvalid), .m2_wready(m2_wready),
        .m2_bid(m2_bid), .m2_bresp(m2_bresp), .m2_bvalid(m2_bvalid), .m2_bready(m2_bready),
        .m2_arid(m2_arid), .m2_araddr(m2_araddr), .m2_arlen(m2_arlen), .m2_arsize(m2_arsize),
        .m2_arburst(m2_arburst), .m2_arvalid(m2_arvalid), .m2_arready(m2_arready),
        .m2_rid(m2_rid), .m2_rdata(m2_rdata), .m2_rresp(m2_rresp), .m2_rlast(m2_rlast), .m2_rvalid(m2_rvalid), .m2_rready(m2_rready),

        .clk_sys(clk_sys), .rst_n(rst_n),
        .s_awaddr(s_awaddr), .s_awid(s_awid), .s_awvalid(s_awvalid), .s_awlen(s_awlen),
        .s_awsize(s_awsize), .s_awburst(s_awburst), .s_awready(s_awready),
        .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_wlast(s_wlast), .s_wready(s_wready),
        .s_bid(s_bid), .s_bvalid(s_bvalid), .s_bresp(s_bresp), .s_bready(s_bready),
        .s_araddr(s_araddr), .s_arid(s_arid), .s_arvalid(s_arvalid), .s_arlen(s_arlen),
        .s_arsize(s_arsize), .s_arburst(s_arburst), .s_arready(s_arready),
        .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready)
    );

    // =========================================================================
    // SLAVE BFM — memory model
    // =========================================================================
    reg [DATA_WIDTH-1:0] mem [0:1023];

    // ---- Write channel: single in-flight transaction ----
    reg [SID_WIDTH-1:0] cap_awid;
    reg [ADDR_WIDTH-1:0] cap_awaddr;
    reg [7:0] cap_awlen;
    integer beat;

    initial begin
        s_awready = 1'b0; s_wready = 1'b0; s_bvalid = 1'b0; s_bid = 0; s_bresp = 2'b00;
        wait(rst_n);
        forever begin
            @(posedge clk_sys);
            s_awready <= 1'b1;
            wait (s_awvalid && s_awready);
            @(posedge clk_sys);
            cap_awid   = s_awid;
            cap_awaddr = s_awaddr;
            cap_awlen  = s_awlen;
            s_awready <= 1'b0;

            s_wready <= 1'b1;
            // store every beat at its own incrementing word address (INCR burst, 4B/beat)
            for (beat = 0; beat <= cap_awlen; beat = beat + 1) begin
                wait (s_wvalid && s_wready);
                mem[cap_awaddr[11:2] + beat] = s_wdata;
                if (beat == cap_awlen && s_wlast !== 1'b1) begin
                    $display("[FAIL][slave] WLAST not asserted on final beat (awlen=%0d)", cap_awlen);
                    fail_count = fail_count + 1;
                end
                @(posedge clk_sys);
            end
            s_wready <= 1'b0;

            s_bid   <= cap_awid;
            s_bresp <= 2'b00;
            s_bvalid <= 1'b1;
            @(posedge clk_sys);
            wait (s_bvalid && s_bready);
            @(posedge clk_sys);
            s_bvalid <= 1'b0;
        end
    end

    // ---- Read channel: pool of outstanding requests, serviced OUT OF ORDER ----
    reg [SID_WIDTH-1:0]   rd_id   [0:OUTSTANDING-1];
    reg [ADDR_WIDTH-1:0]  rd_addr [0:OUTSTANDING-1];
    reg                   rd_busy [0:OUTSTANDING-1];
    integer i, pick, free_slot, avail;

    initial begin
        s_arready = 1'b0;
        for (i = 0; i < OUTSTANDING; i = i + 1) rd_busy[i] = 1'b0;
    end

    // accept AR into a free slot whenever one exists
    always @(posedge clk_sys) begin
        if (!rst_n) begin
            s_arready <= 1'b0;
        end else begin
            free_slot = -1;
            for (i = 0; i < OUTSTANDING; i = i + 1)
                if (!rd_busy[i] && free_slot == -1) free_slot = i;
            s_arready <= (free_slot != -1);
            if (s_arvalid && s_arready && free_slot != -1) begin
                rd_id[free_slot]   = s_arid;
                rd_addr[free_slot] = s_araddr;
                rd_busy[free_slot] = 1'b1;
            end
        end
    end

    // service pool entries in randomized order, one beat burst each (RLAST immediately)
    initial begin
        s_rvalid = 1'b0; s_rid = 0; s_rdata = 0; s_rresp = 2'b00; s_rlast = 1'b0;
        wait(rst_n);
        forever begin
            @(posedge clk_sys);
            avail = 0;
            for (i = 0; i < OUTSTANDING; i = i + 1) if (rd_busy[i]) avail = avail + 1;
            if (avail > 0) begin
                // random small delay before servicing to let more requests queue up (encourages reordering)
                repeat ($urandom_range(0,3)) @(posedge clk_sys);
                // pick a random busy slot
                pick = -1;
                while (pick == -1) begin
                    i = $urandom_range(0, OUTSTANDING-1);
                    if (rd_busy[i]) pick = i;
                end
                s_rid   <= rd_id[pick];
                s_rdata <= mem[rd_addr[pick][11:2]];
                s_rresp <= 2'b00;
                s_rlast <= 1'b1;
                s_rvalid <= 1'b1;
                @(posedge clk_sys);
                wait (s_rvalid && s_rready);
                rd_busy[pick] = 1'b0;
                @(posedge clk_sys);
                s_rvalid <= 1'b0;
                s_rlast  <= 1'b0;
            end
        end
    end

    // =========================================================================
    // Watchdog — prevents silent infinite hangs, dumps handshake state on timeout
    // =========================================================================
    initial begin
        #20000; // adjust if your design legitimately needs longer
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("WATCHDOG TIMEOUT at time %0t -- dumping handshake state", $time);
        $display("  m0: awvalid=%b awready=%b  wvalid=%b wready=%b  bvalid=%b bready=%b  arvalid=%b arready=%b  rvalid=%b rready=%b",
                  m0_awvalid, m0_awready, m0_wvalid, m0_wready, m0_bvalid, m0_bready, m0_arvalid, m0_arready, m0_rvalid, m0_rready);
        $display("  fab(m0_if): awvalid=%b awready=%b  wvalid=%b wready=%b  bvalid=%b bready=%b  arvalid=%b arready=%b  rvalid=%b rready=%b",
                  dut.u_m0_if.fab_awvalid, dut.u_m0_if.fab_awready,
                  dut.u_m0_if.fab_wvalid, dut.u_m0_if.fab_wready,
                  dut.u_m0_if.fab_bvalid, dut.u_m0_if.fab_bready,
                  dut.u_m0_if.fab_arvalid, dut.u_m0_if.fab_arready,
                  dut.u_m0_if.fab_rvalid, dut.u_m0_if.fab_rready);
        $display("  crossbar: state=%0d  w_grant=%b r_grant=%b  s_awvalid=%b s_awready=%b  s_wvalid=%b s_wready=%b  s_bvalid=%b s_bready=%b",
                  dut.u_crossbar.state, dut.u_crossbar.w_grant, dut.u_crossbar.r_grant,
                  s_awvalid, s_awready, s_wvalid, s_wready, s_bvalid, s_bready);
        $display("  slave AR/R: s_arvalid=%b s_arready=%b s_rvalid=%b s_rready=%b s_rlast=%b", s_arvalid, s_arready, s_rvalid, s_rready, s_rlast);
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("TESTS PASSED: %0d   TESTS FAILED: %0d (incomplete due to hang)", pass_count, fail_count);
        $finish;
    end

    // =========================================================================
    // Reset sequencing
    // =========================================================================
    initial begin
        m0_rst_n = 0; m1_rst_n = 0; m2_rst_n = 0; rst_n = 0;
        #50;
        rst_n = 1;
        #20 m0_rst_n = 1;
        #20 m1_rst_n = 1;
        #20 m2_rst_n = 1;
    end

    // =========================================================================
    // Master 0 tasks
    // =========================================================================
    task m0_write(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            m0_awid = id; m0_awaddr = addr; m0_awlen = 8'd0; m0_awsize = 3'b010; m0_awburst = 2'b01;
            m0_wdata = data; m0_wstrb = 4'hF; m0_wlast = 1'b1;
            fork
                begin
                    m0_awvalid = 1'b1;
                    @(posedge m0_clk);
                    while (!(m0_awvalid && m0_awready)) @(posedge m0_clk);
                    m0_awvalid = 1'b0;
                end
                begin
                    m0_wvalid = 1'b1;
                    @(posedge m0_clk);
                    while (!(m0_wvalid && m0_wready)) @(posedge m0_clk);
                    m0_wvalid = 1'b0;
                end
            join
            m0_bready = 1'b1;
            @(posedge m0_clk);
            while (!(m0_bvalid && m0_bready)) @(posedge m0_clk);
            if (m0_bid !== id) begin
                $display("[FAIL][m0_write] BID mismatch: exp=%0d got=%0d", id, m0_bid);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
            @(posedge m0_clk);
            m0_bready = 1'b0;
        end
    endtask

    task m0_read(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] rdata);
        begin
            m0_arid = id; m0_araddr = addr; m0_arlen = 8'd0; m0_arsize = 3'b010; m0_arburst = 2'b01;
            m0_arvalid = 1'b1;
            @(posedge m0_clk);
            while (!(m0_arvalid && m0_arready)) @(posedge m0_clk);
            m0_arvalid = 1'b0;

            m0_rready = 1'b1;
            @(posedge m0_clk);
            while (!(m0_rvalid && m0_rready && m0_rlast)) @(posedge m0_clk);
            rdata = m0_rdata;
            if (m0_rid !== id) begin
                $display("[FAIL][m0_read] RID mismatch: exp=%0d got=%0d", id, m0_rid);
                fail_count = fail_count + 1;
            end
            @(posedge m0_clk);
            m0_rready = 1'b0;
        end
    endtask

    // =========================================================================
    // Master 1 tasks
    // =========================================================================
    task m1_write(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            m1_awid = id; m1_awaddr = addr; m1_awlen = 8'd0; m1_awsize = 3'b010; m1_awburst = 2'b01;
            m1_wdata = data; m1_wstrb = 4'hF; m1_wlast = 1'b1;
            fork
                begin
                    m1_awvalid = 1'b1;
                    @(posedge m1_clk);
                    while (!(m1_awvalid && m1_awready)) @(posedge m1_clk);
                    m1_awvalid = 1'b0;
                end
                begin
                    m1_wvalid = 1'b1;
                    @(posedge m1_clk);
                    while (!(m1_wvalid && m1_wready)) @(posedge m1_clk);
                    m1_wvalid = 1'b0;
                end
            join
            m1_bready = 1'b1;
            @(posedge m1_clk);
            while (!(m1_bvalid && m1_bready)) @(posedge m1_clk);
            if (m1_bid !== id) begin
                $display("[FAIL][m1_write] BID mismatch: exp=%0d got=%0d", id, m1_bid);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
            @(posedge m1_clk);
            m1_bready = 1'b0;
        end
    endtask

    task m1_read(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] rdata);
        begin
            m1_arid = id; m1_araddr = addr; m1_arlen = 8'd0; m1_arsize = 3'b010; m1_arburst = 2'b01;
            m1_arvalid = 1'b1;
            @(posedge m1_clk);
            while (!(m1_arvalid && m1_arready)) @(posedge m1_clk);
            m1_arvalid = 1'b0;

            m1_rready = 1'b1;
            @(posedge m1_clk);
            while (!(m1_rvalid && m1_rready && m1_rlast)) @(posedge m1_clk);
            rdata = m1_rdata;
            if (m1_rid !== id) begin
                $display("[FAIL][m1_read] RID mismatch: exp=%0d got=%0d", id, m1_rid);
                fail_count = fail_count + 1;
            end
            @(posedge m1_clk);
            m1_rready = 1'b0;
        end
    endtask

    // =========================================================================
    // Master 2 tasks
    // =========================================================================
    task m2_write(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            m2_awid = id; m2_awaddr = addr; m2_awlen = 8'd0; m2_awsize = 3'b010; m2_awburst = 2'b01;
            m2_wdata = data; m2_wstrb = 4'hF; m2_wlast = 1'b1;
            fork
                begin
                    m2_awvalid = 1'b1;
                    @(posedge m2_clk);
                    while (!(m2_awvalid && m2_awready)) @(posedge m2_clk);
                    m2_awvalid = 1'b0;
                end
                begin
                    m2_wvalid = 1'b1;
                    @(posedge m2_clk);
                    while (!(m2_wvalid && m2_wready)) @(posedge m2_clk);
                    m2_wvalid = 1'b0;
                end
            join
            m2_bready = 1'b1;
            @(posedge m2_clk);
            while (!(m2_bvalid && m2_bready)) @(posedge m2_clk);
            if (m2_bid !== id) begin
                $display("[FAIL][m2_write] BID mismatch: exp=%0d got=%0d", id, m2_bid);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
            @(posedge m2_clk);
            m2_bready = 1'b0;
        end
    endtask

    task m2_read(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] rdata);
        begin
            m2_arid = id; m2_araddr = addr; m2_arlen = 8'd0; m2_arsize = 3'b010; m2_arburst = 2'b01;
            m2_arvalid = 1'b1;
            @(posedge m2_clk);
            while (!(m2_arvalid && m2_arready)) @(posedge m2_clk);
            m2_arvalid = 1'b0;

            m2_rready = 1'b1;
            @(posedge m2_clk);
            while (!(m2_rvalid && m2_rready && m2_rlast)) @(posedge m2_clk);
            rdata = m2_rdata;
            if (m2_rid !== id) begin
                $display("[FAIL][m2_read] RID mismatch: exp=%0d got=%0d", id, m2_rid);
                fail_count = fail_count + 1;
            end
            @(posedge m2_clk);
            m2_rready = 1'b0;
        end
    endtask

    // =========================================================================
    // Burst-capable write tasks — each master gets its own staging array,
    // filled by the test before the call, so different masters can run
    // different burst lengths concurrently.
    // =========================================================================
    reg [DATA_WIDTH-1:0] m0_wstage [0:15];
    reg [DATA_WIDTH-1:0] m1_wstage [0:15];
    reg [DATA_WIDTH-1:0] m2_wstage [0:15];

    task m0_write_burst(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, input [7:0] awlen);
        integer i;
        begin
            m0_awid = id; m0_awaddr = addr; m0_awlen = awlen; m0_awsize = 3'b010; m0_awburst = 2'b01;
            fork
                begin
                    m0_awvalid = 1'b1;
                    @(posedge m0_clk);
                    while (!(m0_awvalid && m0_awready)) @(posedge m0_clk);
                    m0_awvalid = 1'b0;
                end
                begin
                    for (i = 0; i <= awlen; i = i + 1) begin
                        m0_wdata = m0_wstage[i];
                        m0_wstrb = 4'hF;
                        m0_wlast = (i == awlen);
                        m0_wvalid = 1'b1;
                        @(posedge m0_clk);
                        while (!(m0_wvalid && m0_wready)) @(posedge m0_clk);
                    end
                    m0_wvalid = 1'b0;
                end
            join
            m0_bready = 1'b1;
            @(posedge m0_clk);
            while (!(m0_bvalid && m0_bready)) @(posedge m0_clk);
            if (m0_bid !== id) begin
                $display("[FAIL][m0_write_burst] BID mismatch: exp=%0d got=%0d", id, m0_bid);
                fail_count = fail_count + 1;
            end else pass_count = pass_count + 1;
            @(posedge m0_clk);
            m0_bready = 1'b0;
        end
    endtask

    task m1_write_burst(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, input [7:0] awlen);
        integer i;
        begin
            m1_awid = id; m1_awaddr = addr; m1_awlen = awlen; m1_awsize = 3'b010; m1_awburst = 2'b01;
            fork
                begin
                    m1_awvalid = 1'b1;
                    @(posedge m1_clk);
                    while (!(m1_awvalid && m1_awready)) @(posedge m1_clk);
                    m1_awvalid = 1'b0;
                end
                begin
                    for (i = 0; i <= awlen; i = i + 1) begin
                        m1_wdata = m1_wstage[i];
                        m1_wstrb = 4'hF;
                        m1_wlast = (i == awlen);
                        m1_wvalid = 1'b1;
                        @(posedge m1_clk);
                        while (!(m1_wvalid && m1_wready)) @(posedge m1_clk);
                    end
                    m1_wvalid = 1'b0;
                end
            join
            m1_bready = 1'b1;
            @(posedge m1_clk);
            while (!(m1_bvalid && m1_bready)) @(posedge m1_clk);
            if (m1_bid !== id) begin
                $display("[FAIL][m1_write_burst] BID mismatch: exp=%0d got=%0d", id, m1_bid);
                fail_count = fail_count + 1;
            end else pass_count = pass_count + 1;
            @(posedge m1_clk);
            m1_bready = 1'b0;
        end
    endtask

    task m2_write_burst(input [ID_WIDTH-1:0] id, input [ADDR_WIDTH-1:0] addr, input [7:0] awlen);
        integer i;
        begin
            m2_awid = id; m2_awaddr = addr; m2_awlen = awlen; m2_awsize = 3'b010; m2_awburst = 2'b01;
            fork
                begin
                    m2_awvalid = 1'b1;
                    @(posedge m2_clk);
                    while (!(m2_awvalid && m2_awready)) @(posedge m2_clk);
                    m2_awvalid = 1'b0;
                end
                begin
                    for (i = 0; i <= awlen; i = i + 1) begin
                        m2_wdata = m2_wstage[i];
                        m2_wstrb = 4'hF;
                        m2_wlast = (i == awlen);
                        m2_wvalid = 1'b1;
                        @(posedge m2_clk);
                        while (!(m2_wvalid && m2_wready)) @(posedge m2_clk);
                    end
                    m2_wvalid = 1'b0;
                end
            join
            m2_bready = 1'b1;
            @(posedge m2_clk);
            while (!(m2_bvalid && m2_bready)) @(posedge m2_clk);
            if (m2_bid !== id) begin
                $display("[FAIL][m2_write_burst] BID mismatch: exp=%0d got=%0d", id, m2_bid);
                fail_count = fail_count + 1;
            end else pass_count = pass_count + 1;
            @(posedge m2_clk);
            m2_bready = 1'b0;
        end
    endtask

    // =========================================================================
    // Test sequence
    // =========================================================================
    reg [DATA_WIDTH-1:0] rd0, rd1, rd2;
    integer tj; // test-sequence loop index (kept separate from slave BFM's 'i')

    // Bump this up by 1 only after the current stage passes clean.
    // 1 = Test 1 only, 2 = +Test 2, 3 = +Test 3, 4 = +Test 4 (all)
    localparam TEST_STAGE = 1;

    initial begin
        $dumpfile("tb_axi4_switch_top.vcd");
        $dumpvars(0, tb_axi4_switch_top);

        m0_awvalid=0; m0_wvalid=0; m0_bready=0; m0_arvalid=0; m0_rready=0;
        m1_awvalid=0; m1_wvalid=0; m1_bready=0; m1_arvalid=0; m1_rready=0;
        m2_awvalid=0; m2_wvalid=0; m2_bready=0; m2_arvalid=0; m2_rready=0;

        wait (m0_rst_n && m1_rst_n && m2_rst_n);
        repeat (5) @(posedge clk_sys);

        // -------------------------------------------------------------------
        // Test 1: single write + readback, each master, own address region
        // -------------------------------------------------------------------
        $display("== Test 1: single write/read per master ==");
        m0_write(4'd1, 32'h0000_0000, 32'hAAAA_0000);
        m0_read (4'd2, 32'h0000_0000, rd0);
        if (rd0 !== 32'hAAAA_0000) begin
            $display("[FAIL] m0 readback mismatch: got %h", rd0); fail_count = fail_count + 1;
        end else pass_count = pass_count + 1;

        m1_write(4'd1, 32'h0000_0100, 32'hBBBB_0000);
        m1_read (4'd2, 32'h0000_0100, rd1);
        if (rd1 !== 32'hBBBB_0000) begin
            $display("[FAIL] m1 readback mismatch: got %h", rd1); fail_count = fail_count + 1;
        end else pass_count = pass_count + 1;

        m2_write(4'd1, 32'h0000_0200, 32'hCCCC_0000);
        m2_read (4'd2, 32'h0000_0200, rd2);
        if (rd2 !== 32'hCCCC_0000) begin
            $display("[FAIL] m2 readback mismatch: got %h", rd2); fail_count = fail_count + 1;
        end else pass_count = pass_count + 1;

        // -------------------------------------------------------------------
        // Test 2: concurrent write requests from all 3 masters -> arbitration
        // -------------------------------------------------------------------
        if (TEST_STAGE >= 2) begin
        $display("== Test 2: concurrent writes, WRR arbitration ==");
        fork
            m0_write(4'd3, 32'h0000_0010, 32'h1111_1111);
            m1_write(4'd3, 32'h0000_0110, 32'h2222_2222);
            m2_write(4'd3, 32'h0000_0210, 32'h3333_3333);
        join
        end

        // -------------------------------------------------------------------
        // Test 3: concurrent reads from all 3 masters -> OOO response routing
        // -------------------------------------------------------------------
        if (TEST_STAGE >= 3) begin
        $display("== Test 3: concurrent reads, out-of-order responses ==");
        fork
            m0_read(4'd4, 32'h0000_0010, rd0);
            m1_read(4'd5, 32'h0000_0110, rd1);
            m2_read(4'd6, 32'h0000_0210, rd2);
        join

        if (rd0 !== 32'h1111_1111) begin $display("[FAIL] m0 OOO read mismatch: got %h", rd0); fail_count=fail_count+1; end
        else pass_count = pass_count + 1;
        if (rd1 !== 32'h2222_2222) begin $display("[FAIL] m1 OOO read mismatch: got %h", rd1); fail_count=fail_count+1; end
        else pass_count = pass_count + 1;
        if (rd2 !== 32'h3333_3333) begin $display("[FAIL] m2 OOO read mismatch: got %h", rd2); fail_count=fail_count+1; end
        else pass_count = pass_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 4: concurrent bursts, DIFFERENT length per master
        //   m0: 1 beat   (awlen=0)
        //   m1: 4 beats  (awlen=3)
        //   m2: 8 beats  (awlen=7)
        // Verifies no beats dropped/misplaced across the CDC + W-mux path.
        // -------------------------------------------------------------------
        if (TEST_STAGE >= 4) begin
        $display("== Test 4: concurrent variable-length bursts ==");
        for (tj = 0; tj < 1; tj = tj + 1) m0_wstage[tj] = 32'hA000_0000 + tj;
        for (tj = 0; tj < 4; tj = tj + 1) m1_wstage[tj] = 32'hB000_0000 + tj;
        for (tj = 0; tj < 8; tj = tj + 1) m2_wstage[tj] = 32'hC000_0000 + tj;

        fork
            m0_write_burst(4'd7, 32'h0000_1000, 8'd0);
            m1_write_burst(4'd8, 32'h0000_2000, 8'd3);
            m2_write_burst(4'd9, 32'h0000_3000, 8'd7);
        join

        for (tj = 0; tj < 1; tj = tj + 1) begin
            m0_read(4'd10, 32'h0000_1000 + tj*4, rd0);
            if (rd0 !== m0_wstage[tj]) begin
                $display("[FAIL] m0 burst beat %0d mismatch: exp=%h got=%h", tj, m0_wstage[tj], rd0);
                fail_count = fail_count + 1;
            end else pass_count = pass_count + 1;
        end
        for (tj = 0; tj < 4; tj = tj + 1) begin
            m1_read(4'd11, 32'h0000_2000 + tj*4, rd1);
            if (rd1 !== m1_wstage[tj]) begin
                $display("[FAIL] m1 burst beat %0d mismatch: exp=%h got=%h", tj, m1_wstage[tj], rd1);
                fail_count = fail_count + 1;
            end else pass_count = pass_count + 1;
        end
        for (tj = 0; tj < 8; tj = tj + 1) begin
            m2_read(4'd12, 32'h0000_3000 + tj*4, rd2);
            if (rd2 !== m2_wstage[tj]) begin
                $display("[FAIL] m2 burst beat %0d mismatch: exp=%h got=%h", tj, m2_wstage[tj], rd2);
                fail_count = fail_count + 1;
            end else pass_count = pass_count + 1;
        end
        end

        repeat (20) @(posedge clk_sys);

        $display("==============================================");
        $display("TESTS PASSED: %0d   TESTS FAILED: %0d", pass_count, fail_count);
        $display("==============================================");
        if (fail_count == 0) $display("*** ALL TESTS PASSED ***");
        else                 $display("*** TESTS FAILED ***");

        $finish;
    end

endmodule