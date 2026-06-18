module ar_mux #(
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH = 4
)(
    input wire [1:0] grant, // grant from arbiter

    input wire [ADDR_WIDTH-1:0] m0_araddr,
    input wire [ID_WIDTH-1:0] m0_arid,
    input wire m0_arvalid,
    input wire [7:0] m0_arlen,
    input wire [2:0] m0_arsize,
    input wire [1:0] m0_arburst,
    output wire m0_arready,

    input wire [ADDR_WIDTH-1:0] m1_araddr,
    input wire [ID_WIDTH-1:0] m1_arid,
    input wire m1_arvalid,
    input wire [7:0] m1_arlen,  
    input wire [2:0] m1_arsize,
    input wire [1:0] m1_arburst,
    output wire m1_arready,     

    input wire [ADDR_WIDTH-1:0] m2_araddr,
    input wire [ID_WIDTH-1:0] m2_arid,
    input wire m2_arvalid,
    input wire [7:0] m2_arlen,
    input wire [2:0] m2_arsize,
    input wire [1:0] m2_arburst,
    output wire m2_arready, 

    output reg [ADDR_WIDTH-1:0] s_araddr,
    output reg [ID_WIDTH+1:0] s_arid, //remapped id 
    output reg s_arvalid,
    output reg [7:0] s_arlen,
    output reg [2:0] s_arsize,
    output reg [1:0] s_arburst,
    input wire s_arready


);

assign m0_arready = s_arready && (grant == 2'b00);
assign m1_arready = s_arready && (grant == 2'b01);
assign m2_arready = s_arready && (grant == 2'b10);

always @(*) begin
    case (grant)
        2'b00: begin
            s_arid = {2'b00, m0_arid}; // remap id
            s_araddr = m0_araddr;
            s_arvalid = m0_arvalid;
            s_arlen = m0_arlen; 
            s_arsize = m0_arsize;
            s_arburst = m0_arburst;
        end
        2'b01: begin
            s_arid = {2'b01, m1_arid}; // remap id
            s_araddr = m1_araddr;
            s_arvalid = m1_arvalid;
            s_arlen = m1_arlen;
            s_arsize=m1_arsize;
            s_arburst=m1_arburst;
        end
        2'b10: begin
            s_arid = {2'b10, m2_arid}; // remap id
            s_araddr = m2_araddr;
            s_arvalid = m2_arvalid;
            s_arlen = m2_arlen;
            s_arsize = m2_arsize;
            s_arburst = m2_arburst;
        end
        default: begin
            s_araddr = 0;
            s_arid = 0;
            s_arvalid = 0;
            s_arlen = 0;
            s_arsize = 0;
            s_arburst = 0;
        end
    endcase
end

endmodule
