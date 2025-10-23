`timescale 1ns/1ps

module SingleCycleProc(
  input              reset,        // Active High
  input      [63:0]  startpc,
  output reg [63:0]  currentpc,
  output     [63:0]  MemtoRegOut,  // output of the MemtoReg mux
  input              CLK
);

  // Next PC
  wire [63:0] nextpc;

  // Instruction (raw from memory) – use this everywhere to avoid a 1-cycle skew
  wire [31:0] instruction;

  // -------- Instruction fields (ARM64) decoded from the *current* fetch --------
  // Rt/Rd: [4:0], Rn: [9:5], Rm: [20:16], opcode: [31:21]
  wire [4:0]  Rt      = instruction[4:0];
  wire [4:0]  Rn      = instruction[9:5];
  wire [4:0]  Rm      = instruction[20:16];
  wire [10:0] opcode  = instruction[31:21];

  // Control
  wire Reg2Loc, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Uncondbranch;
  wire [3:0] ALUOp;
  wire [1:0] SignOp;
  wire       IsMovZ;

  // Register file
  wire [63:0] regoutA, regoutB;

  // Sign-extended immediate
  wire [63:0] extimm;

  // ALU
  wire [63:0] aluout;
  wire        zero;

  // Data memory
  wire [63:0] readdata;

  // =======================
  // Program Counter update
  // =======================
  always @(posedge CLK) begin
    if (reset)
      currentpc <= #3 startpc;
    else
      currentpc <= #3 nextpc;
  end

  // -------- Instruction memory (combinational) --------
  InstructionMemory imem (
    .Data   (instruction),
    .Address(currentpc)
  );

  // -------- Control (driven by current instruction) --------
  SC_Control control (
    .Reg2Loc      (Reg2Loc),
    .ALUSrc       (ALUSrc),
    .MemtoReg     (MemtoReg),
    .RegWrite     (RegWrite),
    .MemRead      (MemRead),
    .MemWrite     (MemWrite),
    .Branch       (Branch),
    .Uncondbranch (Uncondbranch),
    .ALUOp        (ALUOp),
    .SignOp       (SignOp),
    .IsMovZ       (IsMovZ),
    .opcode       (opcode)
  );

  // -------- Register File --------
  RegisterFile rf (
    .BusA  (regoutA),
    .BusB  (regoutB),
    .BusW  (MemtoRegOut),     // write-back data
    .RA    (Rn),
    .RB    (Reg2Loc ? Rt : Rm),
    .RW    (Rt),
    .RegWr (RegWrite),
    .Clk   (CLK)
  );

  // -------- Sign Extender (use bits of current instruction) --------
  SignExtender sext (
    .SignExtOut (extimm),
    .Instruction(instruction[25:0]),
    .SignOp     (SignOp),
    .IsMovZ     (IsMovZ)
  );

  // -------- ALU Src mux (RB vs immediate) --------
  wire [63:0] aluB = (ALUSrc) ? extimm : regoutB;

  // -------- ALU --------
  ALU alu (
    .BusW   (aluout),
    .BusA   (regoutA),
    .BusB   (aluB),
    .ALUCtrl(ALUOp),
    .Zero   (zero)
  );

  // -------- Data Memory --------
  DataMemory dmem (
    .ReadData  (readdata),
    .Address   (aluout),
    .WriteData (regoutB),     // STUR writes RB (== Rt when Reg2Loc=1)
    .MemoryRead(MemRead),
    .MemoryWrite(MemWrite),
    .Clock     (CLK)
  );

  // -------- MemtoReg mux (ALU vs Memory) --------
  assign MemtoRegOut = (MemtoReg) ? readdata : aluout;

  // -------- Next PC logic --------
  NextPClogic npc (
    .NextPC       (nextpc),
    .CurrentPC    (currentpc),
    .SignExtImm64 (extimm),
    .Branch       (Branch),
    .ALUZero      (zero),
    .Uncondbranch (Uncondbranch)
  );

`ifndef SYNTHESIS
  // ======== SUPER-TRACE (fires each negedge so values are settled) ========
  always @(negedge CLK) begin
    $display("PC=%04h  instr=%08h  opc[31:21]=%b", currentpc, instruction, opcode);
    $display("  RF idx: Rn=%0d  Rm=%0d  Rt=%0d", Rn, Rm, Rt);
    $display("  RF val: A=%016h  B=%016h  (Reg2Loc=%b -> RB=%s)",
              regoutA, regoutB, Reg2Loc, (Reg2Loc ? "Rt" : "Rm"));
    $display("  ctrl: Reg2Loc=%b MemR=%b MemW=%b Mem2Reg=%b RegWr=%b Br=%b UBr=%b ALUOp=%b SignOp=%b ALUSrc=%b IsMovZ=%b",
              Reg2Loc, MemRead, MemWrite, MemtoReg, RegWrite, Branch, Uncondbranch, ALUOp, SignOp, ALUSrc, IsMovZ);
    $display("  imm=%016h  aluB(sel)=%016h  ALUout=%016h  Zero=%b  NextPC=%04h  Mem[R]=%016h",
              extimm, aluB, aluout, zero, nextpc, readdata);
  end
`endif
endmodule

// -------- Wrapper so the TB's instance name/module match --------
module singlecycle(
  input              reset,
  input      [63:0]  startpc,
  output     [63:0]  currentpc,
  output     [63:0]  MemtoRegOut,
  input              CLK
);
  SingleCycleProc DUT(
    .reset(reset), .startpc(startpc), .currentpc(currentpc),
    .MemtoRegOut(MemtoRegOut), .CLK(CLK)
  );
endmodule
