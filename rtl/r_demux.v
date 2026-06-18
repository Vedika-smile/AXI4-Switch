module r_demux #(
    parameter DATA_WIDTH= 32,
    parameter ID_WIDTH = 4
)(
    input wire [DATA_WIDTH-1:0] s_rdata,
    input wire [ID_WIDTH+1:0] s_rid,
    input wire s_rvalid,
    input wire s_rlast,
    input wire [1:0] s_rresp,
    output wire s_rready,

    output wire [DATA_WIDTH-1:0] m0_rdata,
    output wire [ID_WIDTH-1:0] m0_rid,
    output wire m0_rvalid,
    output wire m0_rlast,
    output wire [1:0] m0_rresp,
    input wire m0_rready,   

    output wire [DATA_WIDTH-1:0] m1_rdata,
    output wire [ID_WIDTH-1:0] m1_rid,
    output wire m1_rvalid,
    output wire m1_rlast,
    output wire [1:0] m1_rresp,
    input wire m1_rready,

    output wire [DATA_WIDTH-1:0] m2_rdata,
    output wire [ID_WIDTH-1:0] m2_rid,
    output wire m2_rvalid,      
    output wire m2_rlast,
    output wire [1:0] m2_rresp,
    input wire m2_rready
);

wire [1:0] mas_sel = s_rid[ID_WIDTH+1:ID_WIDTH];
wire [ID_WIDTH-1:0] orig_rid = s_rid[ID_WIDTH-1:0];

assign m0_rvalid = s_rvalid && (mas_sel == 2'b00);
assign m1_rvalid = s_rvalid && (mas_sel == 2'b01);
assign m2_rvalid = s_rvalid && (mas_sel == 2'b10);  

assign m0_rdata = s_rdata;
assign m1_rdata = s_rdata;
assign m2_rdata = s_rdata;

assign m0_rlast = s_rlast;
assign m1_rlast = s_rlast;
assign m2_rlast = s_rlast;  

assign m0_rid   = orig_rid;
assign m1_rid   = orig_rid;
assign m2_rid   = orig_rid;

assign m0_rresp = s_rresp;
assign m1_rresp = s_rresp;
assign m2_rresp = s_rresp;

assign s_rready = s_rvalid && ((mas_sel == 2'b00) ? m0_rready :
                  (mas_sel == 2'b01) ? m1_rready :
                  (mas_sel == 2'b10) ? m2_rready : 1'b0);


endmodule