module skid_buffer #(
 parameter DATA_WIDTH = 32
)(
 input clk,
 input rst_n,
 
 //slave side (from master) //input interface
 input s_valid,
 output reg s_ready,
 input [DATA_WIDTH-1:0] s_data,

 //master side(to arbiter) //output interface
 output reg m_valid,
 input m_ready,
 output reg [DATA_WIDTH-1:0] m_data
);

reg skid_valid;
reg [DATA_WIDTH-1:0] skid_data;

always@(posedge clk or negedge rst_n) begin
 if(!rst_n) begin
  s_ready <= 1'b1;
  m_valid <=1'b0;
  m_data<={DATA_WIDTH{1'b0}};
  skid_valid <= 1'b0;
  skid_data <= {DATA_WIDTH{1'b0}};
 end else begin

 if (m_ready) begin
  if(skid_valid) begin
   m_valid <=1'b1;
   m_data<=skid_data;
   skid_valid <=1'b0;

 end else if (s_valid) begin
  m_valid <= 1'b1;
  m_data <= s_data;
 end
 else begin
  m_valid <= 1'b0;
 end
end
else begin
 if (s_valid && s_ready && !skid_valid) begin
  skid_valid <= 1'b1;
  skid_data <= s_data;
 end
end

if(skid_valid && !(m_ready)) begin
 s_ready <= 1'b0;
end else begin
 s_ready <= 1'b1;
end
end
end
endmodule
