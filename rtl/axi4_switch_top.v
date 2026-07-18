// =============================================================================
// Module: axi4_switch_top
// Purpose: Top-level 3-master : 1-slave AXI4 switch.
//          Instantiates 3x axi_master_if (per-master CDC firewall) feeding
//          a single crossbar (WRR arbitration, ID remap, mux/demux) that
//          drives one slave in clk_sys domain.
//
// Slave-side ID width = ID_WIDTH + 2 (2-bit master-prefix remap, supports
// up to 4 masters; only 3 used here -> grant values 2'b00/01/10).
// =============================================================================
module axi4_switch_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter FIFO_DEPTH = 16,
    parameter FIFO_PTR   = 4,
    parameter W1 = 1,
    parameter W2 = 2,
    parameter W3 = 4
)(
    // =========================================================================
    // Master 0
    // =========================================================================
    input  wire                    m0_clk,
    input  wire                    m0_rst_n,

    input  wire [ID_WIDTH-1:0]     m0_awid,
    input  wire [ADDR_WIDTH-1:0]   m0_awaddr,
    input  wire [7:0]              m0_awlen,
    input  wire [2:0]              m0_awsize,
    input  wire [1:0]              m0_awburst,
    input  wire                    m0_awvalid,
    output wire                    m0_awready,

    input  wire [DATA_WIDTH-1:0]   m0_wdata,
    input  wire [DATA_WIDTH/8-1:0] m0_wstrb,
    input  wire                    m0_wlast,
    input  wire                    m0_wvalid,
    output wire                    m0_wready,

    output wire [ID_WIDTH-1:0]     m0_bid,
    output wire [1:0]              m0_bresp,
    output wire                    m0_bvalid,
    input  wire                    m0_bready,

    input  wire [ID_WIDTH-1:0]     m0_arid,
    input  wire [ADDR_WIDTH-1:0]   m0_araddr,
    input  wire [7:0]              m0_arlen,
    input  wire [2:0]              m0_arsize,
    input  wire [1:0]              m0_arburst,
    input  wire                    m0_arvalid,
    output wire                    m0_arready,

    output wire [ID_WIDTH-1:0]     m0_rid,
    output wire [DATA_WIDTH-1:0]   m0_rdata,
    output wire [1:0]              m0_rresp,
    output wire                    m0_rlast,
    output wire                    m0_rvalid,
    input  wire                    m0_rready,

    // =========================================================================
    // Master 1
    // =========================================================================
    input  wire                    m1_clk,
    input  wire                    m1_rst_n,

    input  wire [ID_WIDTH-1:0]     m1_awid,
    input  wire [ADDR_WIDTH-1:0]   m1_awaddr,
    input  wire [7:0]              m1_awlen,
    input  wire [2:0]              m1_awsize,
    input  wire [1:0]              m1_awburst,
    input  wire                    m1_awvalid,
    output wire                    m1_awready,

    input  wire [DATA_WIDTH-1:0]   m1_wdata,
    input  wire [DATA_WIDTH/8-1:0] m1_wstrb,
    input  wire                    m1_wlast,
    input  wire                    m1_wvalid,
    output wire                    m1_wready,

    output wire [ID_WIDTH-1:0]     m1_bid,
    output wire [1:0]              m1_bresp,
    output wire                    m1_bvalid,
    input  wire                    m1_bready,

    input  wire [ID_WIDTH-1:0]     m1_arid,
    input  wire [ADDR_WIDTH-1:0]   m1_araddr,
    input  wire [7:0]              m1_arlen,
    input  wire [2:0]              m1_arsize,
    input  wire [1:0]              m1_arburst,
    input  wire                    m1_arvalid,
    output wire                    m1_arready,

    output wire [ID_WIDTH-1:0]     m1_rid,
    output wire [DATA_WIDTH-1:0]   m1_rdata,
    output wire [1:0]              m1_rresp,
    output wire                    m1_rlast,
    output wire                    m1_rvalid,
    input  wire                    m1_rready,

    // =========================================================================
    // Master 2
    // =========================================================================
    input  wire                    m2_clk,
    input  wire                    m2_rst_n,

    input  wire [ID_WIDTH-1:0]     m2_awid,
    input  wire [ADDR_WIDTH-1:0]   m2_awaddr,
    input  wire [7:0]              m2_awlen,
    input  wire [2:0]              m2_awsize,
    input  wire [1:0]              m2_awburst,
    input  wire                    m2_awvalid,
    output wire                    m2_awready,

    input  wire [DATA_WIDTH-1:0]   m2_wdata,
    input  wire [DATA_WIDTH/8-1:0] m2_wstrb,
    input  wire                    m2_wlast,
    input  wire                    m2_wvalid,
    output wire                    m2_wready,

    output wire [ID_WIDTH-1:0]     m2_bid,
    output wire [1:0]              m2_bresp,
    output wire                    m2_bvalid,
    input  wire                    m2_bready,

    input  wire [ID_WIDTH-1:0]     m2_arid,
    input  wire [ADDR_WIDTH-1:0]   m2_araddr,
    input  wire [7:0]              m2_arlen,
    input  wire [2:0]              m2_arsize,
    input  wire [1:0]              m2_arburst,
    input  wire                    m2_arvalid,
    output wire                    m2_arready,

    output wire [ID_WIDTH-1:0]     m2_rid,
    output wire [DATA_WIDTH-1:0]   m2_rdata,
    output wire [1:0]              m2_rresp,
    output wire                    m2_rlast,
    output wire                    m2_rvalid,
    input  wire                    m2_rready,

    // =========================================================================
    // Fabric clock (crossbar + slave)
    // =========================================================================
    input  wire                    clk_sys,
    input  wire                    rst_n,

    // =========================================================================
    // Slave port (clk_sys domain) — ID width includes 2-bit master remap prefix
    // =========================================================================
    output wire [ADDR_WIDTH-1:0]   s_awaddr,
    output wire [ID_WIDTH+1:0]     s_awid,
    output wire                    s_awvalid,
    output wire [7:0]              s_awlen,
    output wire [2:0]              s_awsize,
    output wire [1:0]              s_awburst,
    input  wire                    s_awready,

    output wire [DATA_WIDTH-1:0]     s_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s_wstrb,
    output wire                      s_wvalid,
    output wire                      s_wlast,
    input  wire                      s_wready,

    input  wire [ID_WIDTH+1:0]     s_bid,
    input  wire                    s_bvalid,
    input  wire [1:0]              s_bresp,
    output wire                    s_bready,

    output wire [ADDR_WIDTH-1:0]   s_araddr,
    output wire [ID_WIDTH+1:0]     s_arid,
    output wire                    s_arvalid,
    output wire [7:0]              s_arlen,
    output wire [2:0]              s_arsize,
    output wire [1:0]              s_arburst,
    input  wire                    s_arready,

    input  wire [ID_WIDTH+1:0]     s_rid,
    input  wire [DATA_WIDTH-1:0]   s_rdata,
    input  wire [1:0]              s_rresp,
    input  wire                    s_rlast,
    input  wire                    s_rvalid,
    output wire                    s_rready
);

    // =========================================================================
    // Internal fabric-side wires: master N <-> crossbar (clk_sys domain,
    // original un-remapped IDs, already CDC'd by axi_master_if)
    // =========================================================================
    wire [ID_WIDTH-1:0]     m0_fab_awid, m1_fab_awid, m2_fab_awid;
    wire [ADDR_WIDTH-1:0]   m0_fab_awaddr, m1_fab_awaddr, m2_fab_awaddr;
    wire [7:0]              m0_fab_awlen, m1_fab_awlen, m2_fab_awlen;
    wire [2:0]              m0_fab_awsize, m1_fab_awsize, m2_fab_awsize;
    wire [1:0]              m0_fab_awburst, m1_fab_awburst, m2_fab_awburst;
    wire                    m0_fab_awvalid, m1_fab_awvalid, m2_fab_awvalid;
    wire                    m0_fab_awready, m1_fab_awready, m2_fab_awready;

    wire [DATA_WIDTH-1:0]     m0_fab_wdata, m1_fab_wdata, m2_fab_wdata;
    wire [(DATA_WIDTH/8)-1:0] m0_fab_wstrb, m1_fab_wstrb, m2_fab_wstrb;
    wire                       m0_fab_wvalid, m1_fab_wvalid, m2_fab_wvalid;
    wire                       m0_fab_wlast, m1_fab_wlast, m2_fab_wlast;
    wire                       m0_fab_wready, m1_fab_wready, m2_fab_wready;

    wire [ID_WIDTH-1:0]     m0_fab_bid, m1_fab_bid, m2_fab_bid;
    wire                    m0_fab_bvalid, m1_fab_bvalid, m2_fab_bvalid;
    wire [1:0]              m0_fab_bresp, m1_fab_bresp, m2_fab_bresp;
    wire                    m0_fab_bready, m1_fab_bready, m2_fab_bready;

    wire [ID_WIDTH-1:0]     m0_fab_arid, m1_fab_arid, m2_fab_arid;
    wire [ADDR_WIDTH-1:0]   m0_fab_araddr, m1_fab_araddr, m2_fab_araddr;
    wire [7:0]              m0_fab_arlen, m1_fab_arlen, m2_fab_arlen;
    wire [2:0]              m0_fab_arsize, m1_fab_arsize, m2_fab_arsize;
    wire [1:0]              m0_fab_arburst, m1_fab_arburst, m2_fab_arburst;
    wire                    m0_fab_arvalid, m1_fab_arvalid, m2_fab_arvalid;
    wire                    m0_fab_arready, m1_fab_arready, m2_fab_arready;

    wire [ID_WIDTH-1:0]     m0_fab_rid, m1_fab_rid, m2_fab_rid;
    wire [DATA_WIDTH-1:0]   m0_fab_rdata, m1_fab_rdata, m2_fab_rdata;
    wire [1:0]              m0_fab_rresp, m1_fab_rresp, m2_fab_rresp;
    wire                    m0_fab_rlast, m1_fab_rlast, m2_fab_rlast;
    wire                    m0_fab_rvalid, m1_fab_rvalid, m2_fab_rvalid;
    wire                    m0_fab_rready, m1_fab_rready, m2_fab_rready;

    // =========================================================================
    // Master 0 CDC firewall
    // =========================================================================
    axi_master_if #(
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH), .FIFO_PTR(FIFO_PTR)
    ) u_m0_if (
        .m_clk(m0_clk), .m_rst_n(m0_rst_n),
        .m_awid(m0_awid), .m_awaddr(m0_awaddr), .m_awlen(m0_awlen),
        .m_awsize(m0_awsize), .m_awburst(m0_awburst), .m_awvalid(m0_awvalid), .m_awready(m0_awready),
        .m_wdata(m0_wdata), .m_wstrb(m0_wstrb), .m_wlast(m0_wlast), .m_wvalid(m0_wvalid), .m_wready(m0_wready),
        .m_bid(m0_bid), .m_bresp(m0_bresp), .m_bvalid(m0_bvalid), .m_bready(m0_bready),
        .m_arid(m0_arid), .m_araddr(m0_araddr), .m_arlen(m0_arlen),
        .m_arsize(m0_arsize), .m_arburst(m0_arburst), .m_arvalid(m0_arvalid), .m_arready(m0_arready),
        .m_rid(m0_rid), .m_rdata(m0_rdata), .m_rresp(m0_rresp), .m_rlast(m0_rlast), .m_rvalid(m0_rvalid), .m_rready(m0_rready),

        .clk_sys(clk_sys), .rst_n(rst_n),
        .fab_awid(m0_fab_awid), .fab_awaddr(m0_fab_awaddr), .fab_awlen(m0_fab_awlen),
        .fab_awsize(m0_fab_awsize), .fab_awburst(m0_fab_awburst), .fab_awvalid(m0_fab_awvalid), .fab_awready(m0_fab_awready),
        .fab_wdata(m0_fab_wdata), .fab_wstrb(m0_fab_wstrb), .fab_wlast(m0_fab_wlast), .fab_wvalid(m0_fab_wvalid), .fab_wready(m0_fab_wready),
        .fab_bid(m0_fab_bid), .fab_bresp(m0_fab_bresp), .fab_bvalid(m0_fab_bvalid), .fab_bready(m0_fab_bready),
        .fab_arid(m0_fab_arid), .fab_araddr(m0_fab_araddr), .fab_arlen(m0_fab_arlen),
        .fab_arsize(m0_fab_arsize), .fab_arburst(m0_fab_arburst), .fab_arvalid(m0_fab_arvalid), .fab_arready(m0_fab_arready),
        .fab_rid(m0_fab_rid), .fab_rdata(m0_fab_rdata), .fab_rresp(m0_fab_rresp), .fab_rlast(m0_fab_rlast), .fab_rvalid(m0_fab_rvalid), .fab_rready(m0_fab_rready)
    );

    // =========================================================================
    // Master 1 CDC firewall
    // =========================================================================
    axi_master_if #(
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH), .FIFO_PTR(FIFO_PTR)
    ) u_m1_if (
        .m_clk(m1_clk), .m_rst_n(m1_rst_n),
        .m_awid(m1_awid), .m_awaddr(m1_awaddr), .m_awlen(m1_awlen),
        .m_awsize(m1_awsize), .m_awburst(m1_awburst), .m_awvalid(m1_awvalid), .m_awready(m1_awready),
        .m_wdata(m1_wdata), .m_wstrb(m1_wstrb), .m_wlast(m1_wlast), .m_wvalid(m1_wvalid), .m_wready(m1_wready),
        .m_bid(m1_bid), .m_bresp(m1_bresp), .m_bvalid(m1_bvalid), .m_bready(m1_bready),
        .m_arid(m1_arid), .m_araddr(m1_araddr), .m_arlen(m1_arlen),
        .m_arsize(m1_arsize), .m_arburst(m1_arburst), .m_arvalid(m1_arvalid), .m_arready(m1_arready),
        .m_rid(m1_rid), .m_rdata(m1_rdata), .m_rresp(m1_rresp), .m_rlast(m1_rlast), .m_rvalid(m1_rvalid), .m_rready(m1_rready),

        .clk_sys(clk_sys), .rst_n(rst_n),
        .fab_awid(m1_fab_awid), .fab_awaddr(m1_fab_awaddr), .fab_awlen(m1_fab_awlen),
        .fab_awsize(m1_fab_awsize), .fab_awburst(m1_fab_awburst), .fab_awvalid(m1_fab_awvalid), .fab_awready(m1_fab_awready),
        .fab_wdata(m1_fab_wdata), .fab_wstrb(m1_fab_wstrb), .fab_wlast(m1_fab_wlast), .fab_wvalid(m1_fab_wvalid), .fab_wready(m1_fab_wready),
        .fab_bid(m1_fab_bid), .fab_bresp(m1_fab_bresp), .fab_bvalid(m1_fab_bvalid), .fab_bready(m1_fab_bready),
        .fab_arid(m1_fab_arid), .fab_araddr(m1_fab_araddr), .fab_arlen(m1_fab_arlen),
        .fab_arsize(m1_fab_arsize), .fab_arburst(m1_fab_arburst), .fab_arvalid(m1_fab_arvalid), .fab_arready(m1_fab_arready),
        .fab_rid(m1_fab_rid), .fab_rdata(m1_fab_rdata), .fab_rresp(m1_fab_rresp), .fab_rlast(m1_fab_rlast), .fab_rvalid(m1_fab_rvalid), .fab_rready(m1_fab_rready)
    );

    // =========================================================================
    // Master 2 CDC firewall
    // =========================================================================
    axi_master_if #(
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH), .FIFO_PTR(FIFO_PTR)
    ) u_m2_if (
        .m_clk(m2_clk), .m_rst_n(m2_rst_n),
        .m_awid(m2_awid), .m_awaddr(m2_awaddr), .m_awlen(m2_awlen),
        .m_awsize(m2_awsize), .m_awburst(m2_awburst), .m_awvalid(m2_awvalid), .m_awready(m2_awready),
        .m_wdata(m2_wdata), .m_wstrb(m2_wstrb), .m_wlast(m2_wlast), .m_wvalid(m2_wvalid), .m_wready(m2_wready),
        .m_bid(m2_bid), .m_bresp(m2_bresp), .m_bvalid(m2_bvalid), .m_bready(m2_bready),
        .m_arid(m2_arid), .m_araddr(m2_araddr), .m_arlen(m2_arlen),
        .m_arsize(m2_arsize), .m_arburst(m2_arburst), .m_arvalid(m2_arvalid), .m_arready(m2_arready),
        .m_rid(m2_rid), .m_rdata(m2_rdata), .m_rresp(m2_rresp), .m_rlast(m2_rlast), .m_rvalid(m2_rvalid), .m_rready(m2_rready),

        .clk_sys(clk_sys), .rst_n(rst_n),
        .fab_awid(m2_fab_awid), .fab_awaddr(m2_fab_awaddr), .fab_awlen(m2_fab_awlen),
        .fab_awsize(m2_fab_awsize), .fab_awburst(m2_fab_awburst), .fab_awvalid(m2_fab_awvalid), .fab_awready(m2_fab_awready),
        .fab_wdata(m2_fab_wdata), .fab_wstrb(m2_fab_wstrb), .fab_wlast(m2_fab_wlast), .fab_wvalid(m2_fab_wvalid), .fab_wready(m2_fab_wready),
        .fab_bid(m2_fab_bid), .fab_bresp(m2_fab_bresp), .fab_bvalid(m2_fab_bvalid), .fab_bready(m2_fab_bready),
        .fab_arid(m2_fab_arid), .fab_araddr(m2_fab_araddr), .fab_arlen(m2_fab_arlen),
        .fab_arsize(m2_fab_arsize), .fab_arburst(m2_fab_arburst), .fab_arvalid(m2_fab_arvalid), .fab_arready(m2_fab_arready),
        .fab_rid(m2_fab_rid), .fab_rdata(m2_fab_rdata), .fab_rresp(m2_fab_rresp), .fab_rlast(m2_fab_rlast), .fab_rvalid(m2_fab_rvalid), .fab_rready(m2_fab_rready)
    );

    // =========================================================================
    // Crossbar — arbitration, mux/demux, ID remap, drives the slave directly
    // =========================================================================
    crossbar #(
        .W1(W1), .W2(W2), .W3(W3),
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) u_crossbar (
        .clk_sys(clk_sys), .rst_n(rst_n),

        .m0_fab_awaddr(m0_fab_awaddr), .m0_fab_awid(m0_fab_awid), .m0_fab_awvalid(m0_fab_awvalid),
        .m0_fab_awlen(m0_fab_awlen), .m0_fab_awsize(m0_fab_awsize), .m0_fab_awburst(m0_fab_awburst), .m0_fab_awready(m0_fab_awready),
        .m1_fab_awaddr(m1_fab_awaddr), .m1_fab_awid(m1_fab_awid), .m1_fab_awvalid(m1_fab_awvalid),
        .m1_fab_awlen(m1_fab_awlen), .m1_fab_awsize(m1_fab_awsize), .m1_fab_awburst(m1_fab_awburst), .m1_fab_awready(m1_fab_awready),
        .m2_fab_awaddr(m2_fab_awaddr), .m2_fab_awid(m2_fab_awid), .m2_fab_awvalid(m2_fab_awvalid),
        .m2_fab_awlen(m2_fab_awlen), .m2_fab_awsize(m2_fab_awsize), .m2_fab_awburst(m2_fab_awburst), .m2_fab_awready(m2_fab_awready),

        .s_awaddr(s_awaddr), .s_awid(s_awid), .s_awvalid(s_awvalid),
        .s_awlen(s_awlen), .s_awsize(s_awsize), .s_awburst(s_awburst), .s_awready(s_awready),

        .m0_fab_wdata(m0_fab_wdata), .m0_fab_wstrb(m0_fab_wstrb), .m0_fab_wvalid(m0_fab_wvalid), .m0_fab_wlast(m0_fab_wlast), .m0_fab_wready(m0_fab_wready),
        .m1_fab_wdata(m1_fab_wdata), .m1_fab_wstrb(m1_fab_wstrb), .m1_fab_wvalid(m1_fab_wvalid), .m1_fab_wlast(m1_fab_wlast), .m1_fab_wready(m1_fab_wready),
        .m2_fab_wdata(m2_fab_wdata), .m2_fab_wstrb(m2_fab_wstrb), .m2_fab_wvalid(m2_fab_wvalid), .m2_fab_wlast(m2_fab_wlast), .m2_fab_wready(m2_fab_wready),

        .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_wlast(s_wlast), .s_wready(s_wready),

        .s_bid(s_bid), .s_bvalid(s_bvalid), .s_bresp(s_bresp), .s_bready(s_bready),
        .m0_fab_bid(m0_fab_bid), .m0_fab_bvalid(m0_fab_bvalid), .m0_fab_bresp(m0_fab_bresp), .m0_fab_bready(m0_fab_bready),
        .m1_fab_bid(m1_fab_bid), .m1_fab_bvalid(m1_fab_bvalid), .m1_fab_bresp(m1_fab_bresp), .m1_fab_bready(m1_fab_bready),
        .m2_fab_bid(m2_fab_bid), .m2_fab_bvalid(m2_fab_bvalid), .m2_fab_bresp(m2_fab_bresp), .m2_fab_bready(m2_fab_bready),

        .m0_fab_araddr(m0_fab_araddr), .m0_fab_arid(m0_fab_arid), .m0_fab_arvalid(m0_fab_arvalid),
        .m0_fab_arlen(m0_fab_arlen), .m0_fab_arsize(m0_fab_arsize), .m0_fab_arburst(m0_fab_arburst), .m0_fab_arready(m0_fab_arready),
        .m1_fab_araddr(m1_fab_araddr), .m1_fab_arid(m1_fab_arid), .m1_fab_arvalid(m1_fab_arvalid),
        .m1_fab_arlen(m1_fab_arlen), .m1_fab_arsize(m1_fab_arsize), .m1_fab_arburst(m1_fab_arburst), .m1_fab_arready(m1_fab_arready),
        .m2_fab_araddr(m2_fab_araddr), .m2_fab_arid(m2_fab_arid), .m2_fab_arvalid(m2_fab_arvalid),
        .m2_fab_arlen(m2_fab_arlen), .m2_fab_arsize(m2_fab_arsize), .m2_fab_arburst(m2_fab_arburst), .m2_fab_arready(m2_fab_arready),

        .s_araddr(s_araddr), .s_arid(s_arid), .s_arvalid(s_arvalid),
        .s_arlen(s_arlen), .s_arsize(s_arsize), .s_arburst(s_arburst), .s_arready(s_arready),

        .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),

        .m0_fab_rid(m0_fab_rid), .m0_fab_rdata(m0_fab_rdata), .m0_fab_rresp(m0_fab_rresp), .m0_fab_rlast(m0_fab_rlast), .m0_fab_rvalid(m0_fab_rvalid), .m0_fab_rready(m0_fab_rready),
        .m1_fab_rid(m1_fab_rid), .m1_fab_rdata(m1_fab_rdata), .m1_fab_rresp(m1_fab_rresp), .m1_fab_rlast(m1_fab_rlast), .m1_fab_rvalid(m1_fab_rvalid), .m1_fab_rready(m1_fab_rready),
        .m2_fab_rid(m2_fab_rid), .m2_fab_rdata(m2_fab_rdata), .m2_fab_rresp(m2_fab_rresp), .m2_fab_rlast(m2_fab_rlast), .m2_fab_rvalid(m2_fab_rvalid), .m2_fab_rready(m2_fab_rready)
    );

endmodule