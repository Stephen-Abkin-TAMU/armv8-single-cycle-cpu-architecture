`timescale 1ns/1ps

module ALU(
  output reg [63:0] BusW,
  input      [63:0] BusA,
  input      [63:0] BusB,
  input      [3:0]  ALUCtrl,
  output            Zero
);
  localparam [3:0] ALU_AND   = 4'b0000,
                   ALU_ORR   = 4'b0001,
                   ALU_ADD   = 4'b0010,
                   ALU_SUB   = 4'b0110,
                   ALU_PASSB = 4'b0111;

  always @* begin
    case (ALUCtrl)
      ALU_AND:   BusW = BusA & BusB;
      ALU_ORR:   BusW = BusA | BusB;
      ALU_ADD:   BusW = BusA + BusB;
      ALU_SUB:   BusW = BusA - BusB;
      ALU_PASSB: BusW = BusB;           // used by CBZ path
      default:   BusW = 64'd0;
    endcase
  end

  // Deterministic zero flag: only 1 when every bit is exactly 0; otherwise 0 (even if BusW has X)
  assign Zero = (BusW === 64'd0);

`ifndef SYNTHESIS
  // Compact ALU trace
  always @(*) begin
    case (ALUCtrl)
      ALU_AND:   $display("ALU AND  A=%016h  B=%016h  -> W=%016h", BusA, BusB, BusW);
      ALU_ORR:   $display("ALU OR   A=%016h  B=%016h  -> W=%016h", BusA, BusB, BusW);
      ALU_ADD:   $display("ALU ADD  A=%016h  B=%016h  -> W=%016h", BusA, BusB, BusW);
      ALU_SUB:   $display("ALU SUB  A=%016h  B=%016h  -> W=%016h", BusA, BusB, BusW);
      ALU_PASSB: $display("ALU PASSB (CBZ chk) B=%016h  Zero?=%0d", BusB, Zero);
      default:   $display("ALU ???  A=%016h  B=%016h  -> W=%016h", BusA, BusB, BusW);
    endcase
  end
`endif
endmodule
