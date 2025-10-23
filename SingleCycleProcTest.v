`timescale 1ns / 1ps

`define STRLEN 32
`define HalfClockPeriod 60
`define ClockPeriod (`HalfClockPeriod * 2)

module SingleCycleProcTest_v;

   initial begin
      $dumpfile("singlecycle.vcd");
      $dumpvars;
   end

   task passTest;
      input [63:0] actualOut, expectedOut;
      input [`STRLEN*8:0] testType;
      inout [7:0] passed;
      begin
         $display("\n--- Checking %s ---", testType);
         $display("Expected: 0x%016h", expectedOut);
         $display("Actual:   0x%016h", actualOut);
         if (actualOut === expectedOut) begin
            $display("%s passed\n", testType);
            passed = passed + 1;
         end else begin
            $display("%s failed\n", testType);
         end
      end
   endtask

   task allPassed;
      input [7:0] passed;
      input [7:0] numTests;
      if (passed == numTests)
         $display("All tests passed");
      else
         $display("Some tests failed: %0d of %0d passed", passed, numTests);
   endtask

   // Inputs
   reg  CLK;
   reg  Reset;
   reg [63:0] startPC;
   reg [7:0]  passed;
   reg [15:0] watchdog;

   // Outputs
   wire [63:0] MemtoRegOut;
   wire [63:0] currentPC;

   // UUT
   singlecycle uut (
      .CLK(CLK),
      .reset(Reset),
      .startpc(startPC),
      .currentpc(currentPC),
      .MemtoRegOut(MemtoRegOut)
   );

   // --- helpers ---
   task step;
      begin
         @(posedge CLK);
         @(negedge CLK);
      end
   endtask

   // Wait until PC is known (no Xs) and equals target
   task wait_for_pc;
      input [63:0] target;
      begin
         // Drain X/unknown phase
         while ($isunknown(currentPC)) step();
         // Now wait until we hit the requested PC
         while (currentPC !== target) step();
      end
   endtask

   // Latches to remember last valid MemtoRegOut in each window
   reg [63:0] prevM2R;

   initial begin
      // Initialize
      CLK = 0;
      Reset = 0;
      startPC = 64'h0;
      passed = 0;
      watchdog = 0;

      // ========= Program 1 =========
      #(1 * `ClockPeriod);
      $display("\n=== START PROGRAM 1 @PC=0x0000 ===");
      startPC = 64'h0000;
      Reset = 1;
      step(); // hold reset through one full cycle
      Reset = 0;

      // Sync to the start PC cleanly
      wait_for_pc(64'h0000);

      // Run THROUGH the LDUR at 0x0030 (PC advances to 0x0034 after it)
      prevM2R = 64'h0;
      while (currentPC < 64'h0034) begin
         prevM2R = MemtoRegOut;
         $display("CurrentPC:%h", currentPC);
         step();
      end
      passTest(prevM2R, 64'h0000_0000_0000_000F, "Results of Program 1", passed);

      // ========= Program 2 =========
      #(1 * `ClockPeriod);
      $display("\n=== START PROGRAM 2 @PC=0x0034 ===");
      startPC = 64'h0034;
      Reset = 1;
      step();
      Reset = 0;

      // Sync to 0x0034 start
      wait_for_pc(64'h0034);

      // Run THROUGH the LDUR at 0x0054 (PC becomes 0x0058 after it)
      prevM2R = 64'h0;
      while (currentPC < 64'h0058) begin
         prevM2R = MemtoRegOut;
         $display("CurrentPC:%h", currentPC);
         step();
      end
      passTest(prevM2R, 64'h1234_5678_9ABC_DEF0, "Results of Program 2 (MOVZ build/load)", passed);

      allPassed(passed, 2);
      $finish;
   end

   // Clock
   always #`HalfClockPeriod CLK = ~CLK;

   // Watchdog (kill if sim spins)
   always @(negedge CLK) begin
      watchdog <= watchdog + 1;
      if (watchdog == 16'hFFFF) begin
         $display("Watchdog Timer Expired.");
         $finish;
      end
   end

endmodule
