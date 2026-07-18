//name  - slave_if
module crossbar #(
    parameter W1 = 1,
    parameter W2 = 2,
    parameter W3 = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32, 
    parameter ID_WIDTH = 4
)(
    input wire clk_sys,
    input wire rst_n,

    // ========================================================================
    // WRITE ADDRESS CHANNEL (Masters -> Crossbar)
    // ========================================================================
    input wire [ADDR_WIDTH-1:0]   m0_fab_awaddr, 
    input wire [ID_WIDTH-1:0]     m0_fab_awid,
    input wire                    m0_fab_awvalid,
    input wire [7:0]              m0_fab_awlen,
    input wire [2:0]              m0_fab_awsize,
    input wire [1:0]              m0_fab_awburst,
    output wire                   m0_fab_awready,

    input wire [ADDR_WIDTH-1:0]   m1_fab_awaddr,
    input wire [ID_WIDTH-1:0]     m1_fab_awid,
    input wire                    m1_fab_awvalid,
    input wire [7:0]              m1_fab_awlen,
    input wire [2:0]              m1_fab_awsize,
    input wire [1:0]              m1_fab_awburst,
    output wire                   m1_fab_awready,     

    input wire [ADDR_WIDTH-1:0]   m2_fab_awaddr,
    input wire [ID_WIDTH-1:0]     m2_fab_awid,
    input wire                    m2_fab_awvalid,
    input wire [7:0]              m2_fab_awlen,
    input wire [2:0]              m2_fab_awsize,
    input wire [1:0]              m2_fab_awburst,
    output wire                   m2_fab_awready, 

    // ========================================================================
    // WRITE ADDRESS CHANNEL (Crossbar -> Slave)
    // ========================================================================
    output wire [ADDR_WIDTH-1:0]  s_awaddr,
    output wire [ID_WIDTH+1:0]    s_awid, // remapped id (with master prefix)
    output wire                   s_awvalid,
    output wire [7:0]             s_awlen,
    output wire [2:0]             s_awsize,
    output wire [1:0]             s_awburst,
    input wire                    s_awready,
     
    // ========================================================================
    // WRITE DATA CHANNEL (Masters -> Crossbar)
    // ========================================================================
    input wire [DATA_WIDTH-1:0]     m0_fab_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m0_fab_wstrb,
    input wire                      m0_fab_wvalid,
    input wire                      m0_fab_wlast,
    output wire                     m0_fab_wready,

    input wire [DATA_WIDTH-1:0]     m1_fab_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m1_fab_wstrb,
    input wire                      m1_fab_wvalid,
    input wire                      m1_fab_wlast,
    output wire                     m1_fab_wready,     

    input wire [DATA_WIDTH-1:0]     m2_fab_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m2_fab_wstrb,
    input wire                      m2_fab_wvalid,
    input wire                      m2_fab_wlast,
    output wire                     m2_fab_wready, 

    // ========================================================================
    // WRITE DATA CHANNEL (Crossbar -> Slave)
    // ========================================================================
    output wire [DATA_WIDTH-1:0]    s_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s_wstrb,
    output wire                     s_wvalid,
    output wire                     s_wlast,
    input wire                      s_wready,

    // ========================================================================
    // WRITE RESPONSE CHANNEL 
    // ========================================================================
    input wire [ID_WIDTH+1:0]       s_bid,
    input wire                      s_bvalid,
    input wire [1:0]                s_bresp,
    output wire                     s_bready,

    output wire [ID_WIDTH-1:0]      m0_fab_bid,
    output wire                     m0_fab_bvalid,
    output wire [1:0]               m0_fab_bresp,
    input wire                      m0_fab_bready,

    output wire [ID_WIDTH-1:0]      m1_fab_bid,
    output wire                     m1_fab_bvalid,
    output wire [1:0]               m1_fab_bresp,
    input wire                      m1_fab_bready,

    output wire [ID_WIDTH-1:0]      m2_fab_bid,
    output wire                     m2_fab_bvalid,
    output wire [1:0]               m2_fab_bresp,
    input wire                      m2_fab_bready,

    // ========================================================================
    // READ ADDRESS CHANNEL (Masters -> Crossbar)
    // ========================================================================
    input wire [ADDR_WIDTH-1:0]   m0_fab_araddr,
    input wire [ID_WIDTH-1:0]     m0_fab_arid,
    input wire                    m0_fab_arvalid,
    input wire [7:0]              m0_fab_arlen,
    input wire [2:0]              m0_fab_arsize,
    input wire [1:0]              m0_fab_arburst,
    output wire                   m0_fab_arready,

    input wire [ADDR_WIDTH-1:0]   m1_fab_araddr,
    input wire [ID_WIDTH-1:0]     m1_fab_arid,
    input wire                    m1_fab_arvalid,
    input wire [7:0]              m1_fab_arlen,
    input wire [2:0]              m1_fab_arsize,
    input wire [1:0]              m1_fab_arburst,
    output wire                   m1_fab_arready,     

    input wire [ADDR_WIDTH-1:0]   m2_fab_araddr,
    input wire [ID_WIDTH-1:0]     m2_fab_arid,
    input wire                    m2_fab_arvalid,
    input wire [7:0]              m2_fab_arlen,
    input wire [2:0]              m2_fab_arsize,
    input wire [1:0]              m2_fab_arburst,
    output wire                   m2_fab_arready, 

    // ========================================================================
    // READ ADDRESS CHANNEL (Crossbar -> Slave)
    // ========================================================================
    output wire [ADDR_WIDTH-1:0]  s_araddr,
    output wire [ID_WIDTH+1:0]    s_arid, // remapped id (with master prefix)
    output wire                   s_arvalid,
    output wire [7:0]             s_arlen,
    output wire [2:0]             s_arsize,
    output wire [1:0]             s_arburst,
    input wire                    s_arready,
     
    // ========================================================================
    // READ DATA CHANNEL (Slave -> Crossbar)
    // ========================================================================
    input wire [ID_WIDTH+1:0]     s_rid, 
    input wire [DATA_WIDTH-1:0]   s_rdata,
    input wire [1:0]              s_rresp,
    input wire                    s_rlast,
    input wire                    s_rvalid,
    output wire                   s_rready,

    // ========================================================================
    // READ DATA CHANNEL (Crossbar -> Masters)
    // ========================================================================
    output wire [ID_WIDTH-1:0]    m0_fab_rid,
    output wire [DATA_WIDTH-1:0]  m0_fab_rdata,
    output wire [1:0]             m0_fab_rresp,
    output wire                   m0_fab_rlast,
    output wire                   m0_fab_rvalid,
    input wire                    m0_fab_rready,

    output wire [ID_WIDTH-1:0]    m1_fab_rid,
    output wire [DATA_WIDTH-1:0]  m1_fab_rdata,
    output wire [1:0]             m1_fab_rresp,
    output wire                   m1_fab_rlast,
    output wire                   m1_fab_rvalid,
    input wire                    m1_fab_rready,     

    output wire [ID_WIDTH-1:0]    m2_fab_rid,
    output wire [DATA_WIDTH-1:0]  m2_fab_rdata,
    output wire [1:0]             m2_fab_rresp,
    output wire                   m2_fab_rlast,
    output wire                   m2_fab_rvalid,
    input wire                    m2_fab_rready
);

    // ========================================================================
    // WRITE CONTROL INFRASTRUCTURE
    // ========================================================================
    localparam IDLE     = 2'b00;
    localparam AW_PHASE = 2'b01;
    localparam W_PHASE  = 2'b10;
    
    reg [1:0] state, next_state;

    wire w_req0, w_req1, w_req2;
    wire [1:0] w_grant;
    wire w_arb_advance;

    assign w_req0 = m0_fab_awvalid;
    assign w_req1 = m1_fab_awvalid;
    assign w_req2 = m2_fab_awvalid;

    wrr_arbiter #(
        .W1(W1), .W2(W2), .W3(W3)
    ) write_op (
        .clk(clk_sys),
        .rst_n(rst_n),
        .arb_advance(w_arb_advance),
        .req0(w_req0), .req1(w_req1), .req2(w_req2),
        .grant(w_grant)
    );

    assign w_arb_advance = (state == W_PHASE) && (s_wvalid && s_wready && s_wlast);

    aw_mux #(
        .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) u_aw (
        .grant(w_grant),
        .aw_phase_active(state == AW_PHASE),
        .m0_awaddr(m0_fab_awaddr), .m0_awid(m0_fab_awid), .m0_awvalid(m0_fab_awvalid),
        .m0_awlen(m0_fab_awlen), .m0_awsize(m0_fab_awsize), .m0_awburst(m0_fab_awburst),
        .m0_awready(m0_fab_awready),
        .m1_awaddr(m1_fab_awaddr), .m1_awid(m1_fab_awid), .m1_awvalid(m1_fab_awvalid),
        .m1_awlen(m1_fab_awlen), .m1_awsize(m1_fab_awsize), .m1_awburst(m1_fab_awburst),
        .m1_awready(m1_fab_awready),     
        .m2_awaddr(m2_fab_awaddr), .m2_awid(m2_fab_awid), .m2_awvalid(m2_fab_awvalid),
        .m2_awlen(m2_fab_awlen), .m2_awsize(m2_fab_awsize), .m2_awburst(m2_fab_awburst),
        .m2_awready(m2_fab_awready), 
        .s_awaddr(s_awaddr), .s_awid(s_awid), .s_awvalid(s_awvalid),
        .s_awlen(s_awlen), .s_awsize(s_awsize), .s_awburst(s_awburst),
        .s_awready(s_awready)
    );

    w_mux #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_w_mux (
        .grant(w_grant),
        .w_phase_active(state == W_PHASE),
        .m0_wdata(m0_fab_wdata), .m0_wstrb(m0_fab_wstrb), .m0_wvalid(m0_fab_wvalid), .m0_wlast(m0_fab_wlast), .m0_wready(m0_fab_wready),
        .m1_wdata(m1_fab_wdata), .m1_wstrb(m1_fab_wstrb), .m1_wvalid(m1_fab_wvalid), .m1_wlast(m1_fab_wlast), .m1_wready(m1_fab_wready),
        .m2_wdata(m2_fab_wdata), .m2_wstrb(m2_fab_wstrb), .m2_wvalid(m2_fab_wvalid), .m2_wlast(m2_fab_wlast), .m2_wready(m2_fab_wready),
        .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_wlast(s_wlast), .s_wready(s_wready)
    );

    b_demux #(
        .ID_WIDTH(ID_WIDTH)
    ) u_b_demux (
        .s_bid(s_bid), .s_bvalid(s_bvalid), .s_bresp(s_bresp), .s_bready(s_bready),
        .m0_bid(m0_fab_bid), .m0_bvalid(m0_fab_bvalid), .m0_bresp(m0_fab_bresp), .m0_bready(m0_fab_bready),
        .m1_bid(m1_fab_bid), .m1_bvalid(m1_fab_bvalid), .m1_bresp(m1_fab_bresp), .m1_bready(m1_fab_bready),
        .m2_bid(m2_fab_bid), .m2_bvalid(m2_fab_bvalid), .m2_bresp(m2_fab_bresp), .m2_bready(m2_fab_bready)
    );

    always @(*) begin
        next_state = state;
        case(state)
            IDLE:     if (w_req0 || w_req1 || w_req2) next_state = AW_PHASE;
            AW_PHASE: if (s_awvalid && s_awready)     next_state = W_PHASE;
            W_PHASE:  if (s_wvalid && s_wready && s_wlast) next_state = IDLE; 
            default:  next_state = IDLE;
        endcase
    end

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // ========================================================================
    // READ CONTROL INFRASTRUCTURE (Pure Combinational Matrix)
    // ========================================================================
    wire r_req0, r_req1, r_req2;
    wire [1:0] r_grant;
    wire r_arb_advance;

    assign r_req0 = m0_fab_arvalid;
    assign r_req1 = m1_fab_arvalid;
    assign r_req2 = m2_fab_arvalid;

    wrr_arbiter #(
        .W1(W1), .W2(W2), .W3(W3)
    ) read_op (
        .clk(clk_sys),
        .rst_n(rst_n),
        .arb_advance(r_arb_advance),
        .req0(r_req0), .req1(r_req1), .req2(r_req2),
        .grant(r_grant)
    );

    // Read arbiter advances the instant the address handshake finishes
    assign r_arb_advance = s_arvalid && s_arready;

    //AR INSTANTIATION
    ar_mux #(
        .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) u_ar (
        .grant(r_grant),
        .m0_araddr(m0_fab_araddr), .m0_arid(m0_fab_arid), .m0_arvalid(m0_fab_arvalid),
        .m0_arlen(m0_fab_arlen), .m0_arsize(m0_fab_arsize), .m0_arburst(m0_fab_arburst),
        .m0_arready(m0_fab_arready),
        .m1_araddr(m1_fab_araddr), .m1_arid(m1_fab_arid), .m1_arvalid(m1_fab_arvalid),
        .m1_arlen(m1_fab_arlen), .m1_arsize(m1_fab_arsize), .m1_arburst(m1_fab_arburst),
        .m1_arready(m1_fab_arready),     
        .m2_araddr(m2_fab_araddr), .m2_arid(m2_fab_arid), .m2_arvalid(m2_fab_arvalid),
        .m2_arlen(m2_fab_arlen), .m2_arsize(m2_fab_arsize), .m2_arburst(m2_fab_arburst),
        .m2_arready(m2_fab_arready), 
        .s_araddr(s_araddr), .s_arid(s_arid), .s_arvalid(s_arvalid),
        .s_arlen(s_arlen), .s_arsize(s_arsize), .s_arburst(s_arburst),
        .s_arready(s_arready)
    );

    //R_DEMUX 
    r_demux #(
        .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) u_r_demux (
        .s_rdata(s_rdata), .s_rid(s_rid), .s_rvalid(s_rvalid), .s_rlast(s_rlast), .s_rresp(s_rresp), .s_rready(s_rready),
        .m0_rdata(m0_fab_rdata), .m0_rid(m0_fab_rid), .m0_rvalid(m0_fab_rvalid), .m0_rlast(m0_fab_rlast), .m0_rresp(m0_fab_rresp), .m0_rready(m0_fab_rready),
        .m1_rdata(m1_fab_rdata), .m1_rid(m1_fab_rid), .m1_rvalid(m1_fab_rvalid), .m1_rlast(m1_fab_rlast), .m1_rresp(m1_fab_rresp), .m1_rready(m1_fab_rready),
        .m2_rdata(m2_fab_rdata), .m2_rid(m2_fab_rid), .m2_rvalid(m2_fab_rvalid), .m2_rlast(m2_fab_rlast), .m2_rresp(m2_fab_rresp), .m2_rready(m2_fab_rready)
    );

endmodule
