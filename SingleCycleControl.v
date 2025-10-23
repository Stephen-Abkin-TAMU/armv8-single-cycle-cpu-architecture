`timescale 1ns/1ps

// ====== OPCODE DEFINES (11 MSBs of instruction) ======
`define OPCODE_ADDREG       11'b10001011000  // ADD (reg)
`define OPCODE_SUBREG       11'b11001011000  // SUB (reg)

// Allow a don't-care in bit[24] for AND/ORR (shifted register variants)
`define OPCODE_ANDREG_MASK  11'b1000101000?  // AND (shifted reg)
`define OPCODE_ORRREG_MASK  11'b1010101000?  // ORR (shifted reg)

// I-type groups
`define OPCODE_ADDIMM       11'b100100010??
`define OPCODE_SUBIMM       11'b110100010??
`define OPCODE_MOVZ         11'b110100101??  // MOVZ (hw in [22:21])

// Branches
`define OPCODE_B            11'b000101?????
`define OPCODE_CBZ          11'b10110100???  // CBZ (64-bit)

// D-type
`define OPCODE_LDUR         11'b11111000010
`define OPCODE_STUR         11'b11111000000

module SC_Control(
  output reg       Reg2Loc,
  output reg       ALUSrc,
  output reg       MemtoReg,
  output reg       RegWrite,
  output reg       MemRead,
  output reg       MemWrite,
  output reg       Branch,
  output reg       Uncondbranch,
  output reg [3:0] ALUOp,
  output reg [1:0] SignOp,
  output reg       IsMovZ,         // <--- NEW: drive SignExtender mode
  input      [10:0] opcode
);
  // ALU ops (must match ALU.v)
  localparam [3:0] ALU_AND   = 4'b0000,
                   ALU_ORR   = 4'b0001,
                   ALU_ADD   = 4'b0010,
                   ALU_SUB   = 4'b0110,
                   ALU_PASSB = 4'b0111;

  // SignOp encodings (must match SignExtender.v)
  localparam [1:0] S_I  = 2'b00,   // I-type
                   S_D  = 2'b01,   // D-type
                   S_CB = 2'b10,   // CBZ
                   S_B  = 2'b11;   // B

  always @* begin
    // safe defaults
    Reg2Loc       = 1'b0;
    ALUSrc        = 1'b0;
    MemtoReg      = 1'b0;
    RegWrite      = 1'b0;
    MemRead       = 1'b0;
    MemWrite      = 1'b0;
    Branch        = 1'b0;
    Uncondbranch  = 1'b0;
    ALUOp         = ALU_ADD;   // benign default
    SignOp        = S_I;       // benign default
    IsMovZ        = 1'b0;      // VERY IMPORTANT: default 0

    casez (opcode)
      // -------- D-type --------
      `OPCODE_LDUR: begin
        ALUSrc    = 1'b1;   // base + imm
        MemtoReg  = 1'b1;
        RegWrite  = 1'b1;
        MemRead   = 1'b1;
        ALUOp     = ALU_ADD;
        SignOp    = S_D;
      end

      `OPCODE_STUR: begin
        Reg2Loc   = 1'b1;   // RB <= Rt (store data)
        ALUSrc    = 1'b1;   // base + imm
        MemWrite  = 1'b1;
        ALUOp     = ALU_ADD;
        SignOp    = S_D;
      end

      // -------- R-type --------
      `OPCODE_ADDREG:       begin RegWrite = 1'b1; ALUOp = ALU_ADD; end
      `OPCODE_SUBREG:       begin RegWrite = 1'b1; ALUOp = ALU_SUB; end
      `OPCODE_ANDREG_MASK:  begin RegWrite = 1'b1; ALUOp = ALU_AND; end
      `OPCODE_ORRREG_MASK:  begin RegWrite = 1'b1; ALUOp = ALU_ORR; end

      // -------- I-type --------
      `OPCODE_ADDIMM:       begin ALUSrc=1'b1; RegWrite=1'b1; ALUOp=ALU_ADD; SignOp=S_I; end
      `OPCODE_SUBIMM:       begin ALUSrc=1'b1; RegWrite=1'b1; ALUOp=ALU_SUB; SignOp=S_I; end
      `OPCODE_MOVZ:         begin ALUSrc=1'b1; RegWrite=1'b1; ALUOp=ALU_PASSB; IsMovZ=1'b1; end

      // -------- Branches --------
      `OPCODE_CBZ: begin
        Reg2Loc      = 1'b1;   // RB <= Rt
        Branch       = 1'b1;
        ALUOp        = ALU_PASSB; // feed RB to Zero detector
        SignOp       = S_CB;
      end

      `OPCODE_B: begin
        Uncondbranch = 1'b1;
        SignOp       = S_B;
      end

      default: ; // keep defaults
    endcase
  end

`ifndef SYNTHESIS
  // (Optional) short decoder trace
  always @ (opcode) begin
    casez (opcode)
      `OPCODE_LDUR:        $display("DEC LDUR");
      `OPCODE_STUR:        $display("DEC STUR");
      `OPCODE_ADDREG:      $display("DEC ADD");
      `OPCODE_SUBREG:      $display("DEC SUB");
      `OPCODE_ANDREG_MASK: $display("DEC AND");
      `OPCODE_ORRREG_MASK: $display("DEC ORR");
      `OPCODE_ADDIMM:      $display("DEC ADDI");
      `OPCODE_SUBIMM:      $display("DEC SUBI");
      `OPCODE_MOVZ:        $display("DEC MOVZ");
      `OPCODE_CBZ:         $display("DEC CBZ");
      `OPCODE_B:           $display("DEC B");
      default:             $display("DEC other: %b", opcode);
    endcase
  end
`endif
endmodule
