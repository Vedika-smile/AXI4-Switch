module tb_skid_buffer;

parameter DATA_WIDTH = 32;

reg clk;
reg rst_n;
reg s_valid;
reg [DATA_WIDTH-1:0] s_data;
wire s_ready;
wire m_valid;
reg m_ready;
wire [DATA_WIDTH-1:0] m_data;

skid_buffer #(
 .DATA_WIDTH(DATA_WIDTH)
) dut(
 clk,
 rst_n,
 s_valid,
 s_ready,
 s_data,
 m_valid,
 m_ready,
 m_data
);

initial clk =0;
always #5 clk=~clk;

initial begin
 $dumpfile("sim/tb_skid_buffer.vcd");
 $dumpvars(0,tb_skid_buffer);
end

task send_beat;
    input [DATA_WIDTH-1:0] data;
    begin
        @(negedge clk);          // set data on falling edge
        s_valid = 1;
        s_data  = data;
        @(posedge clk);          // wait for rising edge
        while (!s_ready) begin
            @(posedge clk);
        end
        @(negedge clk);
        s_valid = 0;
    end
endtask

initial begin
 rst_n=0;
 s_valid=0;
 s_data=0;
 m_ready=1;
 #22;
 rst_n =1;
 #10;
 
 //Test 1 : downstream always ready

 $display("Test 1");
 send_beat(32'hAAAA_0001);
 send_beat(32'hBBBB_0002);
 send_beat(32'hCCCC_0003); 
 #20;
 $display("DONE test 1");

 //Downstream stalls

 $display("Test 2");
 m_ready = 0;
 s_valid=1;
 s_data=32'hDEAD_0001;
 #10;
 s_valid=1;
 s_data=32'hCAFE_B112;
 #10;
 m_ready=1;
 #30;
 s_valid = 0;
 #20;
 $display("done test 2");
 
 //back to back transfer

 $display("test 3");
 repeat(8) begin
  s_valid = 1;
  s_data= $random;
  #10;
 end
 s_valid=0;
 #30
$display("done test 3");

//reset during active tranfer
 
 $display("test 4");
 s_valid=1;
 s_data=32'hFFFF_FFFF;
 m_ready = 0;
 #10;
 rst_n=0;
 #4;
 rst_n=1;
 s_valid=0;
 m_ready=1;
 #20;
 $display("done");
 $finish;
end

always @(posedge clk) begin
 if(m_valid && m_ready)
  $display("t=%0t | TRANSFER m_data=0x%08h", $time, m_data);
 if(s_valid && !s_ready)
  $display("t=%0t | BACKPRESSURE s_data=0x%08h held", $time, s_data);
end

endmodule
