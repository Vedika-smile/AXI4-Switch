module TwoFFSynchronizer #(
    parameter DATA_WIDTH = 8
    )(
    input clk,
    input rst,
    input [DATA_WIDTH:0] d_in,
    output reg [DATA_WIDTH:0] d_out
    );
    reg [DATA_WIDTH:0] temp; //metastable
    initial begin
        temp = 0;
        d_out = 0;
    end
    always @(posedge clk) begin
        if(rst) begin
            temp <= 0;
            d_out <= 0;
        end
        else begin
            temp <= d_in;
            d_out <= temp;
        end
    end
endmodule 