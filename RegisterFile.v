`timescale 1ns/1ps

module RegisterFile(
  output [63:0] BusA,
  output [63:0] BusB,
  input  [63:0] BusW,
  input  [4:0]  RA,
  input  [4:0]  RB,
  input  [4:0]  RW,
  input         RegWr,
  input         Clk
);
  // 31 real registers (X0..X30). X31 is XZR and is always 0, reads return 0, writes ignored.
  reg [63:0] regs [0:30];

  integer i;
  initial begin
    for (i = 0; i < 31; i = i + 1)
      regs[i] = 64'd0;
  end

  // ---------- Previous-cycle write capture (for safe bypass) ----------
  reg        prev_we;
  reg [4:0]  prev_rw;
  reg [63:0] prev_wdata;

  wire cur_we_ok = RegWr && (^RW !== 1'bx) && (RW != 5'd31) && (^BusW !== 1'bx);

  always @(posedge Clk) begin
    // commit to array
    if (cur_we_ok)
      regs[RW] <= BusW;

    // capture a *stable* write for NEXT cycle's read-bypass
    prev_we    <= cur_we_ok;
    prev_rw    <= RW;
    prev_wdata <= BusW;
  end

  // ---------- Safe array read helper ----------
  function [63:0] rread;
    input [4:0] idx;
    begin
      if (^idx === 1'bx)       rread = 64'd0;    // unknown index -> 0
      else if (idx == 5'd31)   rread = 64'd0;    // XZR
      else                     rread = regs[idx];
    end
  endfunction

  wire [63:0] readA_raw = rread(RA);
  wire [63:0] readB_raw = rread(RB);

  // ---------- One-cycle-late bypass ----------
  // Only return prev_wdata if it was written LAST cycle to the same reg.
  assign BusA = (prev_we && (RA == prev_rw)) ? prev_wdata : readA_raw;
  assign BusB = (prev_we && (RB == prev_rw)) ? prev_wdata : readB_raw;

`ifndef SYNTHESIS
  always @(posedge Clk) if (cur_we_ok)
    $display("RF  WR: X%0d <= %016h", RW, BusW);
`endif
endmodule
