module tb_wrr_arbiter;

reg clk, rst_n;
reg arb_advance;
reg req0, req1, req2;
wire [1:0] grant;

integer cnt0, cnt1, cnt2;
integer i;

wrr_arbiter #(.W0(1),.W1(2),.W2(4)) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .arb_advance (arb_advance),
    .req0        (req0),
    .req1        (req1),
    .req2        (req2),
    .grant       (grant)
);

// clock — 10ns period
initial clk = 0;
always #5 clk = ~clk;

// task: pulse arb_advance for one cycle and read grant after settling
task do_advance;
    begin
        @(negedge clk);      // drive on negedge — safe from setup/hold
        arb_advance = 1;
        @(negedge clk);      // grant updates on posedge between these two negedges
        arb_advance = 0;
        #1;                  // let combinational settle
    end
endtask

initial begin
    $dumpfile("sim/tb_wrr.vcd");
    $dumpvars(0, tb_wrr_arbiter);

    // init
    rst_n       = 0;
    arb_advance = 0;
    req0        = 0;
    req1        = 0;
    req2        = 0;
    cnt0        = 0;
    cnt1        = 0;
    cnt2        = 0;

    // reset for 3 cycles
    repeat(3) @(negedge clk);
    rst_n = 1;
    repeat(2) @(negedge clk);

    // =========================================================
    // TEST 1: all masters requesting — check 1:2:4 ratio
    // =========================================================
    $display("========================================");
    $display("TEST 1: All masters requesting (70 grants)");
    $display("========================================");
    req0 = 1; req1 = 1; req2 = 1;
    cnt0=0; cnt1=0; cnt2=0;

    for (i=0; i<70; i=i+1) begin
        do_advance;
        case(grant)
            2'b00: cnt0 = cnt0 + 1;
            2'b01: cnt1 = cnt1 + 1;
            2'b10: cnt2 = cnt2 + 1;
            2'b11: $display("  WARNING: grant=11 during active requests at i=%0d", i);
        endcase
    end

    $display("M0 grants: %0d (expected 10)", cnt0);
    $display("M1 grants: %0d (expected 20)", cnt1);
    $display("M2 grants: %0d (expected 40)", cnt2);
    $display("Total:     %0d (expected 70)", cnt0+cnt1+cnt2);

    if (cnt0==10 && cnt1==20 && cnt2==40)
        $display("PASS: WRR ratio correct 1:2:4");
    else
        $display("FAIL: WRR ratio wrong");

    // =========================================================
    // TEST 2: grant holds when arb_advance=0
    // =========================================================
    $display("\n========================================");
    $display("TEST 2: Grant hold when arb_advance=0");
    $display("========================================");

    // get a fresh grant
    do_advance;
    begin : hold_test
        reg [1:0] held_grant;
        held_grant = grant;
        $display("Grant issued: %0b", held_grant);

        // hold arb_advance=0 for 5 cycles
        repeat(5) begin
            @(negedge clk);
            #1;
            if (grant !== held_grant)
                $display("FAIL: grant changed to %0b without arb_advance!", grant);
            else
                $display("PASS: grant=%0b held correctly", grant);
        end
    end

    // =========================================================
    // TEST 3: no requests → grant=11
    // =========================================================
    $display("\n========================================");
    $display("TEST 3: No requests → grant should be 11");
    $display("========================================");
    req0=0; req1=0; req2=0;
    do_advance;
    #1;
    if (grant == 2'b11)
        $display("PASS: grant=11 when no requests");
    else
        $display("FAIL: grant=%0b should be 11", grant);

    // =========================================================
    // TEST 4: only M0 requesting
    // =========================================================
    $display("\n========================================");
    $display("TEST 4: Only M0 requesting");
    $display("========================================");
    req0=1; req1=0; req2=0;
    cnt0=0;

    // reset first so credits reload cleanly
    rst_n=0;
    repeat(2) @(negedge clk);
    rst_n=1;
    repeat(2) @(negedge clk);

    for (i=0; i<5; i=i+1) begin
        do_advance;
        $display("grant=%0b (expected 00)", grant);
        if(grant==2'b00) cnt0=cnt0+1;
    end

    if(cnt0==5)
        $display("PASS: M0 gets all grants when alone");
    else
        $display("FAIL: M0 got %0d/5 grants", cnt0);

    // =========================================================
    // TEST 5: look-ahead — no grant=11 during credit reload
    // =========================================================
    $display("\n========================================");
    $display("TEST 5: No idle cycle during credit reload");
    $display("========================================");
    req0=1; req1=1; req2=1;

    // reset to start fresh round
    rst_n=0;
    repeat(2) @(negedge clk);
    rst_n=1;
    repeat(2) @(negedge clk);

    begin : reload_test
        integer fail_count;
        fail_count = 0;
        // run 14 grants = 2 full rounds of W0+W1+W2=7
        for (i=0; i<14; i=i+1) begin
            do_advance;
            if(grant==2'b11) begin
                $display("FAIL at grant %0d: grant went 11 during active requests!", i);
                fail_count = fail_count + 1;
            end else begin
                $display("grant[%0d]=%0b", i, grant);
            end
        end
        if(fail_count==0)
            $display("PASS: No idle cycles during reload");
    end

    // =========================================================
    // TEST 6: rotation check — print grant sequence
    // =========================================================
    $display("\n========================================");
    $display("TEST 6: Rotation sequence (1 full round)");
    $display("Expected pattern: not always same master first");
    $display("========================================");
    req0=1; req1=1; req2=1;
    rst_n=0;
    repeat(2) @(negedge clk);
    rst_n=1;
    repeat(2) @(negedge clk);

    for (i=0; i<7; i=i+1) begin
        do_advance;
        case(grant)
            2'b00: $display("  grant[%0d] = M0", i);
            2'b01: $display("  grant[%0d] = M1", i);
            2'b10: $display("  grant[%0d] = M2", i);
            2'b11: $display("  grant[%0d] = IDLE (unexpected!)", i);
        endcase
    end

    $display("\n========================================");
    $display("All tests complete");
    $display("========================================");
    $finish;
end

// timeout watchdog
initial begin
    #100000;
    $display("TIMEOUT");
    $finish;
end

endmodule