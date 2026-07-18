module cdc_fifo #(
    parameter DATA_WIDTH = 32, // Width of the AXI payload bus (e.g., WDATA or ARADDR)
    parameter PTR_SIZE   = 4,  // Address pointer bit-width (sets depth to 2^PTR_SIZE)
    parameter DEPTH      = 16  // Total slots available inside the FIFO storage
)(
    // ========================================================================
    // ─── WRITE DOMAIN PORTS (Facing Upstream Master Device) ───
    // ========================================================================
    input  wire                   wr_clk,   // Clock signal for the Master side (e.g., clk_m2)
    input  wire                   wr_rst,   // Active-high reset synchronous to wr_clk
    input  wire                   wr_valid, // Driven by Master: HIGH means Master has valid data to send
    output wire                   fifo_ready, // Driven by FIFO: HIGH means FIFO has empty space to accept data //that means master can write data 
    //changed name from wr_ready to fifo_ready to avoid confusion 
    input  wire [DATA_WIDTH-1:0]  wr_data,  // Data or Address packet payload sent from the Master

    // ========================================================================
    // ─── READ DOMAIN PORTS (Facing Downstream Switch / Skid Buffer) ───
    // ========================================================================
    input  wire                   rd_clk,   // Clock signal for the internal Switch fabric (clk_sys)
    input  wire                   rd_rst,   // Active-high reset synchronous to rd_clk
    output wire                   fifo_valid, // Driven by FIFO: HIGH means FIFO contains valid data for the Switch
    input  wire                   rd_ready, // Driven by Switch/Skid: HIGH means downstream block can accept data
    output wire [DATA_WIDTH-1:0]  rd_data   // Data or Address packet payload sent out to the Switch
);

    // ------------------------------------------------------------------------
    // Internal FIFO Status Wires
    // ------------------------------------------------------------------------
    wire full;  // Asserted by core FIFO when there are zero empty slots left (Write Domain)
    wire empty; // Asserted by core FIFO when there is zero data stored inside (Read Domain)

    // ------------------------------------------------------------------------
    // Unused Pointer Wires (Required by the underlying Async_FIFO port list)
    // ------------------------------------------------------------------------
    wire [PTR_SIZE:0] b_wr_ptr; // Binary write pointer output (not needed at this wrapper level)
    wire [PTR_SIZE:0] b_rd_ptr; // Binary read pointer output (not needed at this wrapper level)

    // ------------------------------------------------------------------------
    // AXI4 Handshake → Internal FIFO Translation Logic
    // ------------------------------------------------------------------------
    
    // Write Enable: We push data into the FIFO only when the Master is 
    // actively presenting valid data (wr_valid) AND the FIFO isn't full (!full).
    wire wr_enb = wr_valid && !full;

    // Read Enable: We pop data out of the FIFO only when the downstream 
    // Skid Buffer/Switch is ready to receive (rd_ready) AND the FIFO actually contains data (!empty).
    wire rd_enb = rd_ready && !empty;

    // AXI wr_ready: Tell the Master we are ready to take data if our storage array isn't full.
    // (This decouples the Master from looking directly at the ultimate Slave's status).
    assign fifo_ready = !full;

    // AXI rd_valid: Tell the downstream Switch/Skid Buffer that we have a valid data packet 
    // waiting for them whenever the FIFO is not empty.
    assign fifo_valid = !empty;

    // ========================================================================
    // Core Asynchronous FIFO Instantiation
    // ========================================================================
    Async_FIFO #(
        .width    (DATA_WIDTH),
        .ptr_size (PTR_SIZE),
        .depth    (DEPTH)
    ) u_async_fifo (
        // ─── Write Side Connections (Master Clock Domain) ───
        .wr_clk   (wr_clk),    // Connects to Master clock source
        .wr_rst   (wr_rst),    // Connects to Master reset line
        .wr_enb   (wr_enb),    // Transformed Write Enable pulse
        .data_in  (wr_data),   // Payload moving from Master into memory
        .full     (full),      // Full flag output mapped to internal wire
        .b_wr_ptr (b_wr_ptr),  // Hook up required dummy pointer wire

        // ─── Read Side Connections (Switch Clock Domain) ───
        .rd_clk   (rd_clk),    // Connects to internal system clock
        .rd_rst   (rd_rst),    // Connects to system reset line
        .rd_enb   (rd_enb),    // Transformed Read Enable pulse
        .data_out (rd_data),   // Payload moving out of memory to Skid Buffer
        .empty    (empty),     // Empty flag output mapped to internal wire
        .b_rd_ptr (b_rd_ptr)   // Hook up required dummy pointer wire
    );

endmodule