module wrr_arbiter #(
    parameter W1 = 1,
    parameter W2 = 2,
    parameter W3 = 4
)(
    input wire clk,
    input wire rst_n,
    input wire arb_advance, // HIGH from Crossbar FSM when ready for NEXT master
    input wire req0,
    input wire req1,
    input wire req2,
    output reg [1:0] grant        // 00=M0, 01=M1, 10=M2, 11=Idle
);

//for true round robin you should know previous grsnt 
reg [3:0] credit0;
reg [3:0] credit1;
reg [3:0] credit2;
reg [1:0] last_grant; //tracks who was served last 

//look ahead credits 
reg [3:0] c0, c1, c2;
 
//look ahead will only get reload - when request exists  , when no active request has creadit
always @(*) begin
    c0 = credit0;
    c1 = credit1;
    c2 = credit2;
    
    if ((req0 || req1 || req2) &&
        !((req0 && credit0 > 0) ||
          (req1 && credit1 > 0) ||
          (req2 && credit2 > 0))) begin
        // reload only requesting masters
        if (req0) c0 = W1;
        if (req1) c1 = W2;
        if (req2) c2 = W3;
    end
end

reg [1:0] next_grant;
always @(*) begin
    next_grant=2'b11; //default

    case(last_grant)
        //if last was M0 then m1->m2->m0
        2'b00: begin
            if(req1 && c1>0) next_grant=2'b01;
            else if (req2 && c2>0) next_grant=2'b10;
            else if (req0 && c0>0) next_grant=2'b00;
            else next_grant=2'b11;
        end
        2'b01: begin
            // last= m1 then m2->m0->m1
            if(req2 && c2>0) next_grant=2'b10;
            else if (req0 && c0>0) next_grant=2'b00;
            else if (req1 && c1>0) next_grant=2'b01;
            else next_grant=2'b11;
        end
        2'b10: begin
            //last=m2 them m0->m1_->m2
            if(req0 && c0>0) next_grant=2'b00;
            else if (req1 && c1>0) next_grant=2'b01;
            else if (req2 && c2>0) next_grant=2'b10;
            else next_grant=2'b11;
        end
        default: begin
            if(req0 && c0>0) next_grant=2'b00;
            else if (req1 && c1>0) next_grant=2'b01;
            else if (req2 && c2>0) next_grant=2'b10;
            else next_grant=2'b11;
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        credit0 <= W1;
        credit1 <= W2;
        credit2 <= W3;
        grant <= 2'b11;
        last_grant <= 2'b11;
    end else if (arb_advance || grant==2'b11) begin
        grant <= next_grant;

        if(next_grant !=2'b11) begin
            last_grant<=next_grant;
            credit0 <=(next_grant==2'b00)?c0-1:c0;
            credit1 <= (next_grant==2'b01) ? c1-1 : c1;
            credit2 <= (next_grant==2'b10) ? c2-1 : c2;
        end else begin
            grant <= 2'b11;
            // only reload requesting masters
            if (req0) credit0 <= W1;
            if (req1) credit1 <= W2;
            if (req2) credit2 <= W3;
        end
    end
end
endmodule 