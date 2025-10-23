`timescale 1ns/1ps

module NextPClogic(
    output reg [63:0] NextPC,
    input      [63:0] CurrentPC,
    input      [63:0] SignExtImm64,
    input             Branch,
    input             ALUZero,
    input             Uncondbranch
);

  // Precompute candidates
  wire [63:0] CurPCInc = CurrentPC + 64'd4;         // PC + 4
  wire [63:0] BranchPC = CurrentPC + SignExtImm64;  // PC + offset

  // Treat unknown ALUZero as 0 (do NOT branch on X)
  wire take_cond_branch = Branch && (ALUZero === 1'b1);

  // Core next-PC selection
  always @* begin
    NextPC = CurPCInc;                 // default: fall-through
    if (Uncondbranch)         NextPC = BranchPC;     // B
    else if (take_cond_branch) NextPC = BranchPC;     // CBZ when Zero==1
  end

`ifndef SYNTHESIS
  // Debug trace: show decision and any X on ALUZero
  always @* begin
    if (Branch && (ALUZero !== 1'b0) && (ALUZero !== 1'b1)) begin
      $display("NPC WARN: ALUZero=X; treating as 0 (no branch)");
    end

    if (Uncondbranch) begin
      $display("NPC DEC: B      PC=0x%016h  imm=0x%016h  target=0x%016h  -> NextPC=0x%016h",
               CurrentPC, SignExtImm64, BranchPC, NextPC);
    end else if (take_cond_branch) begin
      $display("NPC DEC: CB TAK PC=0x%016h  Z=%b  imm=0x%016h  target=0x%016h  -> NextPC=0x%016h",
               CurrentPC, ALUZero, SignExtImm64, BranchPC, NextPC);
    end else begin
      $display("NPC DEC: SEQ    PC=0x%016h  Z=%b  B=%b  CB=%b  +4=0x%016h    -> NextPC=0x%016h",
               CurrentPC, ALUZero, Uncondbranch, Branch, CurPCInc, NextPC);
    end
  end
`endif


`ifndef SYNTHESIS
  always @* begin
    if (Uncondbranch)
      $display("  NPC: B   taken  Cur=%04h Off=%016h -> %04h", CurrentPC, SignExtImm64, NextPC);
    else if (Branch)
      $display("  NPC: CBZ %s  Cur=%04h Off=%016h -> %04h",
               (ALUZero===1'b1) ? "taken" : "not", CurrentPC, SignExtImm64, NextPC);
  end
`endif

endmodule
