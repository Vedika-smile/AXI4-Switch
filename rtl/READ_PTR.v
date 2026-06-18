module READ_PTR #(
 parameter ptr_size = 4
 )(
 input rd_clk,
 input rd_en,
 input rst,
 input [ptr_size: 0] g_wr_ptr_sync,  //rptr from synchronizer
 output reg empty,
 output reg [ptr_size: 0] b_rd_ptr,
 output reg [ptr_size: 0] g_rd_ptr 
 );

 wire [ptr_size:0] b_rd_ptr_next;
 wire [ptr_size:0] g_rd_ptr_next;
 wire rempty;
 
 assign b_rd_ptr_next = b_rd_ptr + (rd_en && !empty);
 assign g_rd_ptr_next = (b_rd_ptr_next >> 1)^ b_rd_ptr_next;

 always @(posedge rd_clk or posedge rst) begin
  if(rst) begin
   b_rd_ptr <= 0;
   g_rd_ptr <= 0;
   empty <= 1;
  end
  
  else begin
   b_rd_ptr <= b_rd_ptr_next;
   g_rd_ptr <= g_rd_ptr_next;
   empty <= rempty;
  end
 end 
 
 assign rempty = (g_wr_ptr_sync == g_rd_ptr_next);

endmodule 
 
 

 
 