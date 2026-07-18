// w_mux.v — corrected
module w_mux #(
    parameter DATA_WIDTH = 32
)(
    input wire [1:0] grant,
    input wire w_phase_active,
    input wire [DATA_WIDTH-1:0] m0_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m0_wstrb,
    input wire m0_wvalid,
    input wire m0_wlast,
    output wire m0_wready,
    input wire [DATA_WIDTH-1:0] m1_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m1_wstrb,
    input wire m1_wvalid,
    input wire m1_wlast,
    output wire m1_wready,
    input wire [DATA_WIDTH-1:0] m2_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m2_wstrb,
    input wire m2_wvalid,
    input wire m2_wlast,
    output wire m2_wready,
    output reg [DATA_WIDTH-1:0] s_wdata,
    output reg [(DATA_WIDTH/8)-1:0] s_wstrb,
    output reg s_wvalid,
    output reg s_wlast,
    input wire s_wready
);

assign m0_wready = s_wready && (grant == 2'b00) && w_phase_active;
assign m1_wready = s_wready && (grant == 2'b01) && w_phase_active;
assign m2_wready = s_wready && (grant == 2'b10) && w_phase_active;

always @(*) begin
    case (grant)
        2'b00: begin
            s_wdata  = m0_wdata;
            s_wstrb  = m0_wstrb;
            s_wvalid = m0_wvalid && w_phase_active;   // ← fix
            s_wlast  = m0_wlast;
        end
        2'b01: begin
            s_wdata  = m1_wdata;
            s_wstrb  = m1_wstrb;
            s_wvalid = m1_wvalid && w_phase_active;   // ← fix
            s_wlast  = m1_wlast;
        end
        2'b10: begin
            s_wdata  = m2_wdata;
            s_wstrb  = m2_wstrb;
            s_wvalid = m2_wvalid && w_phase_active;   // ← fix
            s_wlast  = m2_wlast;
        end
        default: begin
            s_wdata  = 0;
            s_wstrb  = 0;
            s_wvalid = 0;
            s_wlast  = 0;
        end
    endcase
end

endmodule