module aw_mux #(
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH = 4
)(
    input wire [1:0] grant, // grant from arbiter

    input wire [ADDR_WIDTH-1:0] m0_awaddr,
    input wire [ID_WIDTH-1:0] m0_awid,
    input wire m0_awvalid,
    input wire [7:0] m0_awlen,
    input wire [2:0] m0_awsize,
    input wire [1:0] m0_awburst,
    output wire m0_awready,

    input wire [ADDR_WIDTH-1:0] m1_awaddr,
    input wire [ID_WIDTH-1:0] m1_awid,
    input wire m1_awvalid,
    input wire [7:0] m1_awlen,
    input wire [2:0] m1_awsize,
    input wire [1:0] m1_awburst,
    output wire m1_awready,     

    input wire [ADDR_WIDTH-1:0] m2_awaddr,
    input wire [ID_WIDTH-1:0] m2_awid,
    input wire m2_awvalid,
    input wire [7:0] m2_awlen,
    input wire [2:0] m2_awsize,
    input wire [1:0] m2_awburst,
    output wire m2_awready, 

    output reg [ADDR_WIDTH-1:0] s_awaddr,
    output reg [ID_WIDTH+1:0] s_awid, //remapped id 
    output reg s_awvalid,
    output reg [7:0] s_awlen,
    output reg [2:0] s_awsize,
    output reg [1:0] s_awburst,
    input wire s_awready


);

assign m0_awready = s_awready && (grant == 2'b00);
assign m1_awready = s_awready && (grant == 2'b01);
assign m2_awready = s_awready && (grant == 2'b10);

always @(*) begin
    case (grant)
        2'b00: begin
            s_awid = {2'b00, m0_awid}; // remap id
            s_awaddr = m0_awaddr;
            s_awvalid = m0_awvalid;
            s_awlen = m0_awlen;
            s_awsize = m0_awsize;
            s_awburst = m0_awburst;
        end
        2'b01: begin
            s_awid = {2'b01, m1_awid}; // remap id
            s_awaddr = m1_awaddr;
            s_awvalid = m1_awvalid;
            s_awlen = m1_awlen;
            s_awsize = m1_awsize;
            s_awburst = m1_awburst;
        end
        2'b10: begin
            s_awid = {2'b10, m2_awid}; // remap id
            s_awaddr = m2_awaddr;
            s_awvalid = m2_awvalid;
            s_awlen = m2_awlen;
            s_awsize = m2_awsize;
            s_awburst = m2_awburst;
        end
        default: begin
            s_awaddr = 0;
            s_awid = 0;
            s_awvalid = 0;
            s_awlen = 0;
            s_awsize = 0;
            s_awburst = 0;
        end
    endcase
end

endmodule
