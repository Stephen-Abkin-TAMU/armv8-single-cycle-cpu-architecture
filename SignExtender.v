`timescale 1ns/1ps

`define Itype  2'b00
`define Dtype  2'b01
`define CBtype 2'b10
`define Btype  2'b11

module SignExtender(
    output reg [63:0] SignExtOut,
    input      [25:0] Instruction,
    input      [1:0]  SignOp,
    input             IsMovZ            // <--- NEW
);

    // -------- Immediate field slices --------
    wire [11:0] immI   = Instruction[21:10]; // I-type (ADDI/SUBI)
    wire [8:0]  immD   = Instruction[20:12]; // D-type (LDUR/STUR)
    wire [18:0] immCB  = Instruction[23:5];  // CB-type (CBZ)
    wire [25:0] immB   = Instruction[25:0];  // B-type (B)

    // MOVZ fields (live in the same 26 LSBs we already pass in)
    wire [15:0] movz_imm16 = Instruction[20:5];
    wire [1:0]  movz_hw    = Instruction[22:21]; // 0,1,2,3 -> shift by 0,16,32,48

    // -------- Core comb logic --------
    always @* begin
        if (IsMovZ) begin
            // MOVZ: zero-extend and place the 16-bit chunk in the selected halfword
            SignExtOut = (64'h0000_0000_0000_0000 | {48'd0, movz_imm16}) << (16*movz_hw);
        end else begin
            case (SignOp)
                `Itype:  // zero-extend 12-bit immediate (ADDI/SUBI)
                    SignExtOut = {{52{1'b0}}, immI};

                `Dtype:  // sign-extend 9-bit immediate
                    SignExtOut = {{55{immD[8]}}, immD};

                `CBtype: // sign-extend 19-bit immediate, then LSL #2
                    SignExtOut = {{43{immCB[18]}}, immCB, 2'b00};

                `Btype:  // sign-extend 26-bit immediate, then LSL #2
                    SignExtOut = {{36{immB[25]}}, immB, 2'b00};

                default:
                    SignExtOut = 64'd0;
            endcase
        end
    end

`ifndef SYNTHESIS
    // (Optional) Debug prints trimmed for brevity; keep yours if you like.
`endif

endmodule