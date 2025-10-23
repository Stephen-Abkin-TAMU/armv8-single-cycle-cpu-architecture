`timescale 1ns/1ps

module DataMemory(
  output     [63:0] ReadData,
  input      [63:0] Address,     // byte address
  input      [63:0] WriteData,
  input             MemoryRead,
  input             MemoryWrite,
  input             Clock
);
  // 64-bit words, indexed by Address[10:3] => 8-byte aligned
  reg [63:0] mem [0:255];
  integer i;

  // ---------- Initialization for Program 1 ----------
  initial begin
    mem[0] = 64'd1;                               // at address 0x00
    mem[1] = 64'd10;                              // at address 0x08
    mem[2] = 64'd5;                               // at address 0x10
    mem[3] = 64'h0FFBEA7DEADBEEFF;                // at address 0x18
    for (i = 4; i < 256; i = i + 1)
      mem[i] = 64'd0;
  end

  wire [7:0] idx = Address[10:3];   // 8-byte word index

  // ---------- Combinational read (single-cycle) ----------
  assign ReadData = MemoryRead ? mem[idx] : 64'd0;

  // ---------- Synchronous write ----------
  always @(posedge Clock) begin
    if (MemoryWrite)
      mem[idx] <= WriteData;
  end

`ifndef SYNTHESIS
  // Small tracer
  always @* if (MemoryRead)
    $display("DMEM RD  [0x%016h] -> %016h", Address, ReadData);
  always @(posedge Clock) if (MemoryWrite)
    $display("DMEM WR  [0x%016h] <= %016h", Address, WriteData);
`endif
endmodule
