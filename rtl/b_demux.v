module b_demux #(
    parameter ID_WIDTH = 4
)(
    input  wire [ID_WIDTH+1:0]  s_bid,
    input  wire                 s_bvalid,
    input  wire [1:0]           s_bresp,
    output wire                 s_bready,

    output wire [ID_WIDTH-1:0]  m0_bid,
    output wire                 m0_bvalid,
    output wire [1:0]           m0_bresp,
    input  wire                 m0_bready,

    output wire [ID_WIDTH-1:0]  m1_bid,
    output wire                 m1_bvalid,
    output wire [1:0]           m1_bresp,
    input  wire                 m1_bready,

    output wire [ID_WIDTH-1:0]  m2_bid,
    output wire                 m2_bvalid,
    output wire [1:0]           m2_bresp,
    input  wire                 m2_bready
);

// extract fields from remapped BID
wire [1:0]          mas_sel  = s_bid[ID_WIDTH+1:ID_WIDTH];
wire [ID_WIDTH-1:0] orig_bid = s_bid[ID_WIDTH-1:0];

// route valid to correct master only
assign m0_bvalid = s_bvalid && (mas_sel == 2'b00);
assign m1_bvalid = s_bvalid && (mas_sel == 2'b01);
assign m2_bvalid = s_bvalid && (mas_sel == 2'b10);

// original ID goes to all masters
// receiver only looks at it when bvalid=1
assign m0_bid = orig_bid;
assign m1_bid = orig_bid;
assign m2_bid = orig_bid;

// response code goes to all masters
assign m0_bresp = s_bresp;
assign m1_bresp = s_bresp;
assign m2_bresp = s_bresp;

// slave ready when selected master ready
assign s_bready = (mas_sel == 2'b00) ? m0_bready :
                  (mas_sel == 2'b01) ? m1_bready :
                  (mas_sel == 2'b10) ? m2_bready : 1'b0;

endmodule