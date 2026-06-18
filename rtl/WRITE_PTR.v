module WRITE_PTR #(
 parameter ptr_size = 4
 )(
 input wr_clk,
 input wr_en,
 input rst,
 input [ptr_size: 0] g_rptr_sync,  //rptr from synchronizer
 output reg full,
 output reg [ptr_size: 0] b_wptr,
 output reg [ptr_size: 0] g_wptr 
 );

 wire [ptr_size:0] b_wptr_next;
 wire [ptr_size:0] g_wptr_next;
 wire wfull;
 
 assign b_wptr_next = b_wptr + (wr_en && !full);
 assign g_wptr_next = (b_wptr_next >> 1)^ b_wptr_next;

 always @(posedge wr_clk or posedge rst) begin
  if(rst) begin
   b_wptr <= 0;
   g_wptr <= 0;
   full <= 0;
  end
  
  else begin
   b_wptr <= b_wptr_next;
   g_wptr <= g_wptr_next;
  end
 end

 always @(posedge wr_clk or posedge rst) begin 
   if(rst) begin
    full <= 0;
   end

  else begin
   full <= wfull;
  end
 end
 
 assign wfull =( g_rptr_sync =={~g_wptr_next[ptr_size : ptr_size-1], g_wptr_next[ptr_size-2:0]});   //gray two msb bits inverted and in binary only one 
 

endmodule 