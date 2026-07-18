// module axi4_switch_top #(
//     parameter DATA_WIDTH = 32,
//     parameter ADDR_WIDTH = 32,
//     parameter ID_WIDTH   = 4,
//     parameter STRB_WIDTH  = DATA_WIDTH / 8
// )(
//     input clk_sys, //switch domain clock 
//     input rst_n, //active high 
//     input clk_m0, clk_m1, clk_m2,
//     input rst_n_m2, rst_n_m1, rst_n_m0,   

//     //============================================================
//     //master_1 : 1 mbps
//     //===========================================================
//     //AW channel
//     input [ADDR_WIDTH-1:0] m0_awaddr,
//     input [ID_WIDTH-1:0] m0_awid,
//     input [7:0] m0_awlen,
//     input [2:0] m0_awsize,
//     input [1:0] m0_awburst,
//     input m0_awvalid,
//     output m0_awready,
    
//     //w channel
//     input [DATA_WIDTH-1:0] m0_wdata,
//     input [DATA_WIDTH/8-1:0] m0_wstrb,
//     input m0_wlast,
//     input m0_wvalid,
//     output m0_wready,

//     //b channel
//     output [ID_WIDTH-1:0] m0_bid,
//     output [1:0] m0_bresp,
//     output m0_bvalid,
//     input m0_bready,

//     //AR channel 
//     input [ADDR_WIDTH-1:0] m0_araddr,
//     input [ID_WIDTH-1:0] m0_arid,
//     input [7:0] m0_arlen,
//     input [2:0] m0_arsize,
//     input [1:0] m0_arburst,
//     input m0_arvalid,
//     output m0_arready,

//     //r channel
//     output [ID_WIDTH-1:0] m0_rid,
//     output [DATA_WIDTH-1:0] m0_rdata,
//     output [1:0] m0_rresp,
//     output m0_rlast,
//     output m0_rvalid,
//     input m0_rready,
//     //======================================================
//     //Master 2: 2 Mbps
//     //======================================================
//     //AW channel

//     input [ADDR_WIDTH-1:0] m1_awaddr,
//     input [ID_WIDTH-1:0] m1_awid,
//     input [7:0] m1_awlen,
//     input [2:0] m1_awsize,
//     input [1:0] m1_awburst, 
//     input m1_awvalid,
//     output m1_awready,

//     //w channel
//     input [DATA_WIDTH-1:0] m1_wdata,
//     input [DATA_WIDTH/8-1:0] m1_wstrb,
//     input m1_wlast,
//     input m1_wvalid,
//     output m1_wready,   

//     //b channel
//     output [ID_WIDTH-1:0] m1_bid,
//     output [1:0] m1_bresp,
//     output m1_bvalid,
//     input m1_bready,    

//     //AR channel
//     input [ADDR_WIDTH-1:0] m1_araddr,
//     input [ID_WIDTH-1:0] m1_arid,
//     input [7:0] m1_arlen,
//     input [2:0] m1_arsize,
//     input [1:0] m1_arburst,
//     input m1_arvalid,
//     output m1_arready,

//     //r channel
//     output [ID_WIDTH-1:0] m1_rid,
//     output [DATA_WIDTH-1:0] m1_rdata,
//     output [1:0] m1_rresp,
//     output m1_rlast,
//     output m1_rvalid,
//     input m1_rready,    

//     //======================================================
//     //Master 3: 4Mbps 
//     //======================================================
//     //AW channel
//     input [ADDR_WIDTH-1:0] m2_awaddr,
//     input [ID_WIDTH-1:0] m2_awid,
//     input [7:0] m2_awlen,
//     input [2:0] m2_awsize,  
//     input [1:0] m2_awburst,
//     input m2_awvalid,
//     output m2_awready,

//     //w channel
//     input [DATA_WIDTH-1:0] m2_wdata,
//     input [DATA_WIDTH/8-1:0] m2_wstrb,
//     input m2_wlast,
//     input m2_wvalid,
//     output m2_wready,   

//     //b channel
//     output [ID_WIDTH-1:0] m2_bid,
//     output [1:0] m2_bresp,
//     output m2_bvalid,
//     input m2_bready,

//     //AR channel
//     input [ADDR_WIDTH-1:0] m2_araddr,
//     input [ID_WIDTH-1:0] m2_arid,
//     input [7:0] m2_arlen,
//     input [2:0] m2_arsize,
//     input [1:0] m2_arburst,
//     input m2_arvalid,
//     output m2_arready,

//     //r channel
//     output [ID_WIDTH-1:0] m2_rid,
//     output [DATA_WIDTH-1:0] m2_rdata,
//     output [1:0] m2_rresp,
//     output m2_rlast,
//     output m2_rvalid,
//     input m2_rready

//      //==================================================================
//     //slave interface
//     //======================================================================
//     //AW channel
//     output [ADDR_WIDTH-1:0] s_awaddr,
//     output [ID_WIDTH-1:0] s_awid,
//     output [7:0] s_awlen,
//     output [2:0] s_awsize,
//     output [1:0] s_awburst,
//     output s_awvalid,
//     input s_awready,

//     //w channel
//     output [DATA_WIDTH-1:0] s_wdata,
//     output [STRB_WIDTH-1:0] s_wstrb,
//     output s_wlast,
//     output s_wvalid,
//     input s_wready,

//     //b channel
//     input [ID_WIDTH+1:0] s_bid,
//     input [1:0] s_bresp,
//     input s_bvalid,
//     output s_bready,
    
//     //AR channel
//     output [ADDR_WIDTH-1:0] s_araddr,
//     output [ID_WIDTH+1:0] s_arid,
//     output [7:0] s_arlen,
//     output [2:0] s_arsize,
//     output [1:0] s_arburst,
//     output s_arvalid,
//     input s_arready,    

//     //r channel
//     input [ID_WIDTH+1:0] s_rid,
//     input [DATA_WIDTH-1:0] s_rdata,
//     input [1:0] s_rresp,
//     input s_rlast,
//     input s_rvalid,
//     output s_rready
// );

// wire [2:0] m_clks = {clk_m2,clk_m1,clk_m0};
// wire [2:0] m_rst_ns = {rst_n_m2, rst_n_m1, rst_n_m0};

// // 1. Declare internal signals as arrays - AW CHANNEL
// wire [3:0]   fifo_awid     [0:2];
// wire [1:0]   fifo_awburst  [0:2];
// wire [2:0]   fifo_awsize   [0:2];
// wire [7:0]   fifo_awlen    [0:2];
// wire [31:0]  fifo_awaddr   [0:2];
// wire fifo_awvalid [0:2];
// wire fifo_awready [0:2];

// //2. W CHANNEL 
// wire fifo_wvalid [2:0];
// wire fifo_wready [2:0];
// wire fifo_wlast [2:0];
// wire [31:0] fifo_wdata [2:0];
// wire [3:0] fifo_wstrb [2:0];

// //3. AR CHANNEL 
// wire [3:0]   fifo_arid     [0:2];
// wire [1:0]   fifo_arburst  [0:2];
// wire [2:0]   fifo_arsize   [0:2];
// wire [7:0]   fifo_arlen    [0:2];
// wire [31:0]  fifo_araddr   [0:2];
// wire fifo_arvalid [0:2];
// wire fifo_arready [0:2];

// //R channel 
//  wire [38:0] fabric_payload [0:2]; 
    
//     // The Demux steering logic (running on clk_sys)
//     always @(*) begin
//         // Default: nobody gets a valid pulse
//         fabric_rvalid[0] = 1'b0;
//         fabric_rvalid[1] = 1'b0;
//         fabric_rvalid[2] = 1'b0;

//         // Use the 2-bit prefix (bits [5:4] of s_rid) to steer the transaction
//         if (s_rvalid) begin
//             case (s_rid[5:4])
//                 2'b00: fabric_rvalid[0] = s_rvalid;
//                 2'b01: fabric_rvalid[1] = s_rvalid;
//                 2'b10: fabric_rvalid[2] = s_rvalid;
//                 default: ;
//             endcase
//         end
//     end

//     //B channel 
//     always @(*) begin
//         // Default: nobody gets a valid pulse
//         fabric_bvalid[0] = 1'b0;
//         fabric_bvalid[1] = 1'b0;
//         fabric_bvalid[2] = 1'b0;

//         // Use the 2-bit prefix (bits [5:4] of s_rid) to steer the transaction
//         if (s_rvalid) begin
//             case (s_rid[5:4])
//                 2'b00: fabric_bvalid[0] = s_bvalid;
//                 2'b01: fabric_bvalid[1] = s_bvalid;
//                 2'b10: fabric_bvalid[2] = s_bvalid;
//                 default: ;
//             endcase
//         end
//     end

// ///============================================================================================================
// // CDC FIFO intantiation 
// //=============================================================================================================

// genvar i;
// generate
//     //write address channel - widht is 49 bits (32+8+4+3+2) (addr +len+id+ size + burst)- DOWNSTREAM 
//     for (i=0; i<3; i=i+1) begin: gen_fifo_aw
//         wire [48:0] fabric_payload;
//         wire [48:0] master_payload;

//         assign master_payload= (i==0)?{m0_awid,m0_awburst,m0_awsize,m0_awlen,m0_awaddr}:
//                                 (i==1)?{m1_awid,m1_awburst,m1_awsize,m1_awlen,m1_awaddr}:
//                                         {m2_awid,m2_awburst,m2_awsize,m2_awlen,m2_awaddr};

//         cdc_fifo #(.DATA_WIDTH(49), .PTR_SIZE(4), .DEPTH(16)
//         ) u_fifo_aw (
//             .wr_clk   (m_clks[i]),
//             .wr_rst   (m_rst_ns[i]),
//             .wr_valid ((i==0) ? m0_awvalid : (i==1)?m1_awvalid:m2_awvalid),
//             .wr_ready ((i==0) ? m0_awready : (i==1)?m1_awready:m2_awready),
//             .wr_data  (master_payload),

//             .rd_clk (clk_sys),
//             .rd_rst   (rst_n),
//             .rd_valid (fifo_awvalid[i]), //internal vector array feeding skid buffer 
//             .rd_ready (fifo_awready[i]), //internal vector array from skid buffers
//             .rd_data (fabric_payload)
//         );
//         //unpack payload into internal fabric wires heading to skid buffers 
//         assign fifo_awid[i] = fabric_payload[48:45];
//         assign fifo_awburst[i] = fabric_payload[44:43];
//         assign fifo_awsize[i] = fabric_payload[42:40];
//         assign fifo_awlen[i] = fabric_payload[39:32];
//         assign fifo_awaddr[i] = fabric_payload[31:0];
//     end

//     //WRITE DATA CHANNEL - WIDTH +LAST +STRB = 32+1+4 = 37 BITS - DOWNSTREAM
//     for (i=0; i<3; i=i+1) begin : gen_fifo_w
//         wire [36:0] fabric_payload;
//         wire [36:0] master_payload;

//         assign master_payload = (i==0)?{m0_wlast,m0_wstrb,m0_wdata}:
//                                 (i==1)?{m1_wlast,m1_wstrb,m1_wdata}:
//                                         {m2_wlast,m2_wstrb,m2_wdata};

//         cdc_fifo #(.DATA_WIDTH(37), .PTR_SIZE(4), .DEPTH(16)
//         ) u_fifo_w (
//             .wr_clk   (m_clks[i]),
//             .wr_rst   (m_rst_ns[i]),
//             .wr_valid ((i==0) ? m0_wvalid : (i==1)?m1_wvalid:m2_wvalid),
//             .wr_ready ((i==0) ? m0_wready : (i==1)?m1_wready:m2_wready),
//             .wr_data  (master_payload),

//             .rd_clk (clk_sys),
//             .rd_rst   (rst_n),
//             .rd_valid (fifo_wvalid[i]), //internal vector array feeding skid buffer 
//             .rd_ready (fifo_wready[i]), //internal vector array from skid buffers
//             .rd_data (fabric_payload)
//         );
//         //unpack payload into internal fabric wires heading to skid buffers 
//         assign fifo_wdata[i] = fabric_payload[31:0];
//         assign fifo_wstrb[i] = fabric_payload[35:32];
//         assign fifo_wlast[i] = fabric_payload[36];
//     end

//     //read address channel - widht is 49 bits (32+8+4+3+2) (addr +len+id+ size + burst)- DOWNSTREAM 
//     for (i=0; i<3; i=i+1) begin: gen_fifo_ar
//         wire [48:0] fabric_payload;
//         wire [48:0] master_payload;

//         assign master_payload= (i==0)?{m0_arid,m0_arburst,m0_arsize,m0_arlen,m0_araddr}:
//                                 (i==1)?{m1_arid,m1_arburst,m1_arsize,m1_arlen,m1_araddr}:
//                                         {m2_arid,m2_arburst,m2_arsize,m2_arlen,m2_araddr};

//         cdc_fifo #(.DATA_WIDTH(49), .PTR_SIZE(4), .DEPTH(16)
//         ) u_fifo_ar (
//             .wr_clk   (m_clks[i]),
//             .wr_rst   (m_rst_ns[i]),
//             .wr_valid ((i==0) ? m0_arvalid : (i==1)?m1_arvalid:m2_arvalid),
//             .wr_ready ((i==0) ? m0_arready : (i==1)?m1_arready:m2_arready),
//             .wr_data  (master_payload),

//             .rd_clk (clk_sys),
//             .rd_rst   (rst_n),
//             .rd_valid (fifo_arvalid[i]), //internal vector array feeding skid buffer 
//             .rd_ready (fifo_arready[i]), //internal vector array from skid buffers
//             .rd_data (fabric_payload)
//         );
//         //unpack payload into internal fabric wires heading to skid buffers 
//         assign fifo_arid[i] = fabric_payload[48:45];
//         assign fifo_arburst[i] = fabric_payload[44:43];
//         assign fifo_arsize[i] = fabric_payload[42:40];
//         assign fifo_arlen[i] = fabric_payload[39:32];
//         assign fifo_araddr[i] = fabric_payload[31:0];
//     end

//     // Read Data Channel (R) - UPSTREAM -  39 Bits!

//     for (i = 0; i < 3; i = i + 1) begin : gen_fifo_r
//         wire [38:0] wdata_payload;

//         // PACKING: Notice we ONLY pass s_rid[3:0] (the native 4-bit ID!)
//         assign wdata_payload = {s_rid[3:0], s_rlast, s_rresp, s_rdata};
        
//         cdc_fifo #(
//             .DATA_WIDTH(39), // Corrected down to 39 bits!
//             .PTR_SIZE(4), 
//             .DEPTH(16)
//         ) u_fifo_r (
//             .wr_clk   (clk_sys), 
//             .wr_rst   (rst_n),
//             .wr_valid (fabric_rvalid[i]), 
//             .wr_ready (fabric_rready[i]), 
//             .wr_data  (wdata_payload),

//             .rd_clk   (m_clks[i]),
//             .rd_rst   (m_rst_ns[i]),
//             .rd_valid ( (i == 0) ? m0_rvalid : (i == 1) ? m1_rvalid : m2_rvalid ),
//             .rd_ready ( (i == 0) ? m0_rready : (i == 1) ? m1_rready : m2_rready ),
//             .rd_data  (fabric_payload[i])
//         );

//         // UNPACKING: Connects clean 4-bit ID directly to the master port
//         if (i == 0) begin
//             assign {m0_rid, m0_rlast, m0_rresp, m0_rdata} = fabric_payload[0];
//         end 
//         else if (i == 1) begin
//             assign {m1_rid, m1_rlast, m1_rresp, m1_rdata} = fabric_payload[1];
//         end 
//         else begin
//             assign {m2_rid, m2_rlast, m2_rresp, m2_rdata} = fabric_payload[2];
//         end
//     end

//     // B - write response channel - UPSTREAM - bid + bresp = 4+2=6
//     for (i=0; i<3; i=i+1) begin: gen_fifo_b
//         wire [5:0] b_payload;

//         assign b_payload={s_bid[3:0],s_bresp};

//         cdc_fifo #(.DATA_WIDTH(6), .PTR_SIZE(4), .DEPTH(16)
//         ) u_fifo_b (
//             .wr_clk   (clk_sys), 
//             .wr_rst   (rst_n),
//             .wr_valid (fabric_bvalid[i]), 
//             .wr_ready (fabric_bready[i]), 
//             .wr_data  (b_payload),

//             .rd_clk   (m_clks[i]),
//             .rd_rst   (m_rst_ns[i]),
//             .rd_valid ( (i == 0) ? m0_bvalid : (i == 1) ? m1_bvalid : m2_bvalid ),
//             .rd_ready ( (i == 0) ? m0_bready : (i == 1) ? m1_bready : m2_bready ),
//             .rd_data  (fabric_payload[i])
//         );
    
//     if (i == 0) begin
//             assign {m0_bid,m0_bresp = fabric_payload[0];
//         end 
//         else if (i == 1) begin
//             assign {m1_bid, m1_bresp} = fabric_payload[1];
//         end 
//         else begin
//             assign {m2_bid, m2_bresp} = fabric_payload[2];
//         end
//     end

// endgenerate

// //==================================
// //look for b and r channel generate after arbiter instantiation 
// //==================================

// //==========================================================
// //for now not using skid buffer 
// //==========================================================

// //master sends  write request and as write address gives address coreesponding to that write will be performed
// //B channel is single to many so it uses demux
// //we require one wrr arbiter for write adress 

// //----------------WRITE ---------------------------------------------

// wire w_req0 = fifo_awvalid[0]; 
// wire w_req1 = fifo_awvalid[1];
// wire w_req2 = fifo_awvalid[2];

// wire w_grant0, w_grant1, w_grant2; // Changed from reg to wire

// wrr_arbiter #(
//     .W1(1), .W2(2), .W3(4)
// ) u_wrr_write ( // Unique instance name
//     .clk    (clk_sys),
//     .rst_n  (rst_n),
//     .req0   (w_req0),
//     .req1   (w_req1),
//     .req2   (w_req2),
//     .grant0 (w_grant0),
//     .grant1 (w_grant1),
//     .grant2 (w_grant2)
// );

// // READ adrress will need arbiter
// //as one salve is there so demux is used for read channel
// //-----------------READ ----------------------

// wire r_req0 = fifo_arvalid[0]; // Fixed hyphen syntax error
// wire r_req1 = fifo_arvalid[1];
// wire r_req2 = fifo_arvalid[2];

// wire r_grant0, r_grant1, r_grant2; // Changed from reg to wire

// wrr_arbiter #(
//     .W1(1), .W2(2), .W3(4)
// ) u_wrr_read (
//     .clk    (clk_sys),
//     .rst_n  (rst_n),
//     .req0   (r_req0),
//     .req1   (r_req1),
//     .req2   (r_req2),
//     .grant0 (r_grant0),
//     .grant1 (r_grant1),
//     .grant2 (r_grant2)
// );

// // --------AW mux ------------

