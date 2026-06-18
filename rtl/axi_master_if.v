// =============================================================================
// Module: axi_master_if
// Purpose: Clock domain crossing firewall for ONE AXI4 master
//
// DOWNSTREAM (AW, W, AR): master_clk → clk_sys via CDC FIFO
//   - Packs signals into single bus, pushes through FIFO, unpacks on fab side
//
// UPSTREAM (B, R): clk_sys → master_clk via CDC FIFO + skid buffer
//   - fab_bid, fab_rid arrive ALREADY STRIPPED of prefix by b_demux/r_demux
//   - Skid buffer on master clock side absorbs backpressure from master
//
// CDC FIFO port names match your cdc_fifo.v exactly:
//   wr_clk, wr_rst (active HIGH), wr_valid, wr_ready, wr_data
//   rd_clk, rd_rst (active HIGH), rd_valid, rd_ready, rd_data
//
// =============================================================================
module axi_master_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter FIFO_DEPTH = 16,
    parameter FIFO_PTR   = 4
)(
    // =========================================================================
    // Master clock domain
    // =========================================================================
    input wire m_clk,
    input wire m_rst_n,          // active LOW (your top uses rst_n_m0 etc.)

    // AW — from master
    input  wire [ID_WIDTH-1:0]     m_awid,
    input  wire [ADDR_WIDTH-1:0]   m_awaddr,
    input  wire [7:0]              m_awlen,
    input  wire [2:0]              m_awsize,
    input  wire [1:0]              m_awburst,
    input  wire                    m_awvalid,
    output wire                    m_awready, //fifo tell master that it has space 

    // W — from master
    input  wire [DATA_WIDTH-1:0]   m_wdata,
    input  wire [DATA_WIDTH/8-1:0] m_wstrb,
    input  wire                    m_wlast,
    input  wire                    m_wvalid,
    output wire                    m_wready,  // fifo tells master it has space 

    // B — to master
    output wire [ID_WIDTH-1:0]     m_bid,
    output wire [1:0]              m_bresp,
    output wire                    m_bvalid, //tells master fifo has data 
    input  wire                    m_bready,

    // AR — from master
    input  wire [ID_WIDTH-1:0]     m_arid,
    input  wire [ADDR_WIDTH-1:0]   m_araddr,
    input  wire [7:0]              m_arlen,
    input  wire [2:0]              m_arsize,
    input  wire [1:0]              m_arburst,
    input  wire                    m_arvalid,
    output wire                    m_arready, //tells master that fifo has room for data --- !full

    // R — to master
    output wire [ID_WIDTH-1:0]     m_rid,
    output wire [DATA_WIDTH-1:0]   m_rdata,
    output wire [1:0]              m_rresp,
    output wire                    m_rlast,
    output wire                    m_rvalid, //tells master fifo has data  // !empty
    input  wire                    m_rready,

    // =========================================================================
    // Fabric / crossbar clock domain (clk_sys)
    // =========================================================================
    input wire clk_sys,
    input wire rst_n,            // active LOW — matches your top rst_n

    // AW out — to crossbar arbiter/mux (original ID, no remapping)
    output wire [ID_WIDTH-1:0]     fab_awid,
    output wire [ADDR_WIDTH-1:0]   fab_awaddr,
    output wire [7:0]              fab_awlen,
    output wire [2:0]              fab_awsize,
    output wire [1:0]              fab_awburst,
    output wire                    fab_awvalid, //fifo has data tells switch
    input  wire                    fab_awready,

    // W out — to crossbar w_mux
    output wire [DATA_WIDTH-1:0]   fab_wdata,
    output wire [DATA_WIDTH/8-1:0] fab_wstrb,
    output wire                    fab_wlast,
    output wire                    fab_wvalid, //fifo has data tells swicth
    input  wire                    fab_wready,

    // B in — from b_demux (already stripped, original ID width)
    input  wire [ID_WIDTH-1:0]     fab_bid,
    input  wire [1:0]              fab_bresp,
    input  wire                    fab_bvalid,
    output wire                    fab_bready,   //fifo can accept has room tells switch

    // AR out — to crossbar arbiter/mux (original ID, no remapping)
    output wire [ID_WIDTH-1:0]     fab_arid,
    output wire [ADDR_WIDTH-1:0]   fab_araddr,
    output wire [7:0]              fab_arlen,
    output wire [2:0]              fab_arsize,
    output wire [1:0]              fab_arburst,
    output wire                    fab_arvalid, //fifo has data tells switch
    input  wire                    fab_arready,

    // R in — from r_demux (already stripped, original ID width)
    input  wire [ID_WIDTH-1:0]     fab_rid,
    input  wire [DATA_WIDTH-1:0]   fab_rdata,
    input  wire [1:0]              fab_rresp,
    input  wire                    fab_rlast,
    input  wire                    fab_rvalid,
    output wire                    fab_rready   //tells switch fifo has room for data 
);

// =============================================================================
// Localparams — packed bus widths
// AW/AR : id+burst+size+len+addr = 4+2+3+8+32 = 49 bits
// W     : last+strb+data         = 1+4+32      = 37 bits
// B     : bid+bresp              = 4+2          = 6  bits
// R     : rid+rlast+rresp+rdata  = 4+1+2+32    = 39 bits
// =============================================================================
localparam AW_W = ID_WIDTH + 2 + 3 + 8 + ADDR_WIDTH; // 49
localparam W_W  = 1 + (DATA_WIDTH/8) + DATA_WIDTH;    // 37
localparam B_W  = ID_WIDTH + 2;                        // 6
localparam R_W  = ID_WIDTH + 1 + 2 + DATA_WIDTH;      // 39
 
// =============================================================================
// DOWNSTREAM: AW channel   m_clk → clk_sys
// pack:   {awid, awburst, awsize, awlen, awaddr}
// =============================================================================
wire [AW_W-1:0] aw_wr_data;
wire [AW_W-1:0] aw_rd_data;
 
assign aw_wr_data = {m_awid, m_awburst, m_awsize, m_awlen, m_awaddr};
 
cdc_fifo #(
    .DATA_WIDTH (AW_W),
    .PTR_SIZE   (FIFO_PTR),
    .DEPTH      (FIFO_DEPTH)
) u_cdc_aw (
    .wr_clk     (m_clk),
    .wr_rst     (~m_rst_n),
    .wr_valid   (m_awvalid),
    .fifo_ready (m_awready),   // FIFO→master: "I have space"
    .wr_data    (aw_wr_data),
    .rd_clk     (clk_sys),
    .rd_rst     (~rst_n),
    .fifo_valid (fab_awvalid), // FIFO→crossbar: "I have data"
    .rd_ready   (fab_awready), // crossbar→FIFO: grant && s_awready
    .rd_data    (aw_rd_data)
);
 
assign fab_awid    = aw_rd_data[48:45];
assign fab_awburst = aw_rd_data[44:43];
assign fab_awsize  = aw_rd_data[42:40];
assign fab_awlen   = aw_rd_data[39:32];
assign fab_awaddr  = aw_rd_data[31:0];
 
// =============================================================================
// DOWNSTREAM: W channel   m_clk → clk_sys
// pack:   {wlast, wstrb, wdata}
// unpack: [36]=last [35:32]=strb [31:0]=data
// =============================================================================
wire [W_W-1:0] w_wr_data;
wire [W_W-1:0] w_rd_data;
 
assign w_wr_data = {m_wlast, m_wstrb, m_wdata};
 
cdc_fifo #(
    .DATA_WIDTH (W_W),
    .PTR_SIZE   (FIFO_PTR),
    .DEPTH      (FIFO_DEPTH)
) u_cdc_w (
    .wr_clk     (m_clk),
    .wr_rst     (~m_rst_n),
    .wr_valid   (m_wvalid),
    .fifo_ready (m_wready),    // FIFO→master
    .wr_data    (w_wr_data),
    .rd_clk     (clk_sys),
    .rd_rst     (~rst_n),
    .fifo_valid (fab_wvalid),  // FIFO→crossbar
    .rd_ready   (fab_wready),
    .rd_data    (w_rd_data)
);

assign fab_wlast  = w_rd_data[36];
assign fab_wstrb  = w_rd_data[35:32];
assign fab_wdata  = w_rd_data[31:0];
 
// =============================================================================
// DOWNSTREAM: AR channel   m_clk → clk_sys
// pack:   {arid, arburst, arsize, arlen, araddr}
// unpack: [48:45]=id [44:43]=burst [42:40]=size [39:32]=len [31:0]=addr
// =============================================================================
wire [AW_W-1:0] ar_wr_data;
wire [AW_W-1:0] ar_rd_data;
 
assign ar_wr_data = {m_arid, m_arburst, m_arsize, m_arlen, m_araddr};
 
cdc_fifo #(
    .DATA_WIDTH (AW_W),
    .PTR_SIZE   (FIFO_PTR),
    .DEPTH      (FIFO_DEPTH)
) u_cdc_ar (
    .wr_clk     (m_clk),
    .wr_rst     (~m_rst_n),
    .wr_valid   (m_arvalid),
    .fifo_ready (m_arready),   // FIFO→master
    .wr_data    (ar_wr_data),
    .rd_clk     (clk_sys),
    .rd_rst     (~rst_n),
    .fifo_valid (fab_arvalid), // FIFO→crossbar
    .rd_ready   (fab_arready),
    .rd_data    (ar_rd_data)
);
 
assign fab_arid    = ar_rd_data[48:45];
assign fab_arburst = ar_rd_data[44:43];
assign fab_arsize  = ar_rd_data[42:40];
assign fab_arlen   = ar_rd_data[39:32];
assign fab_araddr  = ar_rd_data[31:0];
 
// =============================================================================
// UPSTREAM: B channel   clk_sys → m_clk
// fab_bid already stripped by b_demux (original ID_WIDTH)
// pack:   {bid, bresp}
// unpack: [5:2]=bid [1:0]=bresp
// =============================================================================
wire [B_W-1:0] b_wr_data;
wire [B_W-1:0] b_rd_data_raw;
wire           b_fifo_rd_valid;
wire           b_fifo_rd_ready;
 
assign b_wr_data  = {fab_bid, fab_bresp};
 
cdc_fifo #(
    .DATA_WIDTH (B_W),
    .PTR_SIZE   (FIFO_PTR),
    .DEPTH      (FIFO_DEPTH)
) u_cdc_b (
    .wr_clk     (clk_sys),
    .wr_rst     (~rst_n),
    .wr_valid   (fab_bvalid),
    .fifo_ready (fab_bready),  // FIFO→crossbar: "I have space"
    .wr_data    (b_wr_data),
    .rd_clk     (m_clk),
    .rd_rst     (~m_rst_n),
    .fifo_valid (b_fifo_rd_valid), // FIFO→skid //fifo_valid means fifo has data !empty
    .rd_ready   (b_fifo_rd_ready), // skid→FIFO
    .rd_data    (b_rd_data_raw)
);

// Skid buffer — absorbs backpressure when master deasserts m_bready
wire [B_W-1:0] b_skid_out;
wire           b_skid_valid;
wire           b_skid_ready;
 
skid_buffer #(.DATA_WIDTH(B_W)) u_skid_b (
    .clk     (m_clk),
    .rst_n   (m_rst_n),
    .s_valid (b_fifo_rd_valid),
    .s_ready (b_fifo_rd_ready),
    .s_data  (b_rd_data_raw),
    .m_valid (b_skid_valid),
    .m_ready (b_skid_ready),
    .m_data  (b_skid_out)
);
 
assign m_bvalid    = b_skid_valid;
assign b_skid_ready = m_bready;
assign m_bid       = b_skid_out[5:2];
assign m_bresp     = b_skid_out[1:0];
 
// =============================================================================
// UPSTREAM: R channel   clk_sys → m_clk
// fab_rid already stripped by r_demux (original ID_WIDTH)
// pack:   {rid, rlast, rresp, rdata}
// unpack: [38:35]=rid [34]=rlast [33:32]=rresp [31:0]=rdata
// =============================================================================
wire [R_W-1:0] r_wr_data;
wire [R_W-1:0] r_rd_data_raw;
wire           r_fifo_rd_valid;
wire           r_fifo_rd_ready;
 
assign r_wr_data  = {fab_rid, fab_rlast, fab_rresp, fab_rdata};
 
cdc_fifo #(
    .DATA_WIDTH (R_W),
    .PTR_SIZE   (FIFO_PTR),
    .DEPTH      (FIFO_DEPTH)
) u_cdc_r (
    .wr_clk     (clk_sys),
    .wr_rst     (~rst_n),
    .wr_valid   (fab_rvalid),
    .fifo_ready (fab_rready),  // FIFO→crossbar: "I have space"
    .wr_data    (r_wr_data),
    .rd_clk     (m_clk),
    .rd_rst     (~m_rst_n),
    .fifo_valid (r_fifo_rd_valid), // FIFO→skid
    .rd_ready   (r_fifo_rd_ready), // skid→FIFO
    .rd_data    (r_rd_data_raw)
);
 
// Skid buffer — absorbs backpressure when master deasserts m_rready
wire [R_W-1:0] r_skid_out;
wire           r_skid_valid;
wire           r_skid_ready;
 
skid_buffer #(.DATA_WIDTH(R_W)) u_skid_r (
    .clk     (m_clk),
    .rst_n   (m_rst_n),
    .s_valid (r_fifo_rd_valid),
    .s_ready (r_fifo_rd_ready),
    .s_data  (r_rd_data_raw),
    .m_valid (r_skid_valid),
    .m_ready (r_skid_ready),
    .m_data  (r_skid_out)
);
 
assign m_rvalid    = r_skid_valid;
assign r_skid_ready = m_rready;
assign m_rid       = r_skid_out[38:35];
assign m_rlast     = r_skid_out[34];
assign m_rresp     = r_skid_out[33:32];
assign m_rdata     = r_skid_out[31:0];
 
endmodule
 
