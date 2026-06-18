module wrr_arbiter #(
    parameter W1 = 1,
    parameter W2 = 2,
    parameter W3 = 4
)(
    input wire clk,
    input  wire rst_n, // active LOW reset

    input wire req0,
    input wire req1,
    input wire req2,
    // output reg grant0, -> 00
    // output reg grant1,  -> 01
    // output reg grant2 -> 10
    output reg [1:0] grant;
);

reg credit0;   // master 1 credits (max W1=1)
reg [1:0] credit1;   // master 2 credits (max W2=2)
reg [2:0] credit2;   // master 3 credits (max W3=4)

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        credit0 <= W1;
        credit1 <= W2;
        credit2 <= W3;
        grant <= 2'b11;
       
    end else begin
        if(req2 && credit2 > 0) begin
            grant <= 2'b10;
            
            credit2 <= credit2 - 1;
        end else if(req1 && credit1 > 0) begin
            grant <= 2'b01;
            credit1 <= credit1 - 1;
        end else if(req0 && credit0 > 0) begin
            grant<= 2'b00;
            credit0 <= credit0 - 1;
        end else begin
            grant<= 2'b11;
            credit0 <= W1;
            credit1 <= W2;
            credit2 <= W3;
        end
end
end
endmodule
