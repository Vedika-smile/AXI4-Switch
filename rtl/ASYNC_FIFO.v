module Async_FIFO #(
 parameter width = 8,
 parameter ptr_size = 4,
 parameter depth = 16
 )(
 input wr_enb,
 input wr_clk,
 input wr_rst, //actuve high 
 input [width-1:0] data_in,
 output [ptr_size:0] b_wr_ptr,
 input rd_enb,
 input rd_clk,
 input rd_rst, //active high 
 output [width-1:0] data_out,
 output [ptr_size:0] b_rd_ptr,
 output full,
 output empty   // not reg bcoz continuous assignment in submodule 
 );

 wire [ptr_size:0] g_wr_ptr;
 wire [ptr_size:0] g_rd_ptr;
 wire [ptr_size:0] g_wr_ptr_sync;
 wire [ptr_size:0] g_rd_ptr_sync;           //continuous assign so wire 

 fifo_mem #(
  .width(width),
  .ptr_size(ptr_size),
  .depth(depth)
 ) MEM (
  .d_in(data_in),
  .wr_ptr(b_wr_ptr),
  .rd_ptr(b_rd_ptr),
  .wr_clk(wr_clk),
  .rd_clk(rd_clk),
  .full(full),
  .empty(empty),
  .wr_en(wr_enb),
  .rd_en(rd_enb),
  .d_out(data_out)
 );

 WRITE_PTR #(
  .ptr_size(ptr_size)
 ) W_handler (
  .wr_clk(wr_clk),
  .wr_en(wr_enb),
  .rst(wr_rst),
  .g_rptr_sync(g_rd_ptr_sync),
  .full(full),
  .b_wptr(b_wr_ptr),
  .g_wptr(g_wr_ptr)
 );

 READ_PTR #(
  .ptr_size(ptr_size)
  ) R_handler (
  .rd_clk(rd_clk),
  .rd_en(rd_enb),
  .rst(rd_rst),
  .g_wr_ptr_sync(g_wr_ptr_sync),
  .empty(empty),
  .b_rd_ptr(b_rd_ptr),
  .g_rd_ptr(g_rd_ptr)
 );

 TwoFFSynchronizer #(
  .DATA_WIDTH(ptr_size)
 ) F1 (
  .clk(wr_clk),
  .rst(wr_rst),
  .d_in(g_rd_ptr),
  .d_out(g_rd_ptr_sync)
 );

 TwoFFSynchronizer #(
  .DATA_WIDTH(ptr_size)
 ) F2 (
  .clk(rd_clk),
  .rst(rd_rst),
  .d_in(g_wr_ptr),
  .d_out(g_wr_ptr_sync)
 );

endmodule