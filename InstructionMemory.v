`timescale 1ns / 1ps
/*
 * Module: InstructionMemory
 *
 * Implements read-only instruction memory
 */
module InstructionMemory(Data, Address);
   parameter T_rd = 20;
   parameter MemSize = 40;

   output [31:0] Data;
   input  [63:0] Address;
   reg    [31:0] Data;

   always @ (Address) begin
      case (Address)

        // =========================
        // Test Program 1 (spec)
        // =========================
        // 0x000: LDUR X9,  [XZR, 0x0]   // 1
        63'h000: Data = 32'hF84003E9;
        // 0x004: LDUR X10, [XZR, 0x8]   // 10
        63'h004: Data = 32'hF84083EA;
        // 0x008: LDUR X11, [XZR, 0x10]  // 5
        63'h008: Data = 32'hF84103EB;
        // 0x00C: LDUR X12, [XZR, 0x18]  // big const
        63'h00C: Data = 32'hF84183EC;
        // 0x010: LDUR X13, [XZR, 0x20]  // 0 -> counter
        63'h010: Data = 32'hF84203ED;

        // 0x014: ORR X10, X10, X11      // mask = 0xF
        63'h014: Data = 32'hAA0B014A;
        // 0x018: AND X12, X12, X10      // X12 &= 0xF  (== 0xF)
        63'h018: Data = 32'h8A0A018C;

        // loop:
        // 0x01C: CBZ X12, end
        63'h01C: Data = 32'hB400008C;
        // 0x020: ADD X13, X13, X9       // cnt++
        63'h020: Data = 32'h8B0901AD;
        // 0x024: SUB X12, X12, X9       // X12--
        63'h024: Data = 32'hCB09018C;
        // 0x028: B loop                  // back to 0x01C
        63'h028: Data = 32'h17FFFFFD;
        // 0x02C: STUR X13, [XZR, 0x20]  // write result
        63'h02C: Data = 32'hF80203ED;
        // 0x030: LDUR X13, [XZR, 0x20]  // place on bus for checking
        63'h030: Data = 32'hF84203ED;

        // =========================
        // Test Program 2 (MOVZ build + store/load)
        // Starts at 0x034
        // Build X9 = 0x1234_5678_9ABC_DEF0 using MOVZ (passB) + ORR
        // 0x034: MOVZ (passB) X9,  0x1234 << 48
        63'h034: Data = 32'hD2E24689;  // imm16=0x1234, hw=3
        // 0x038: MOVZ (passB) X10, 0x5678 << 32
        63'h038: Data = 32'hD2CACF0A;  // imm16=0x5678, hw=2
        // 0x03C: ORR  X9, X9, X10
        63'h03C: Data = 32'hAA0A0129;

        // 0x040: MOVZ (passB) X10, 0x9ABC << 16
        63'h040: Data = 32'hD2B3578A;  // imm16=0x9ABC, hw=1
        // 0x044: ORR  X9, X9, X10
        63'h044: Data = 32'hAA0A0129;

        // 0x048: MOVZ (passB) X10, 0xDEF0 << 0
        63'h048: Data = 32'hD29BDE0A;  // imm16=0xDEF0, hw=0
        // 0x04C: ORR  X9, X9, X10      // X9 = 0x123456789ABCDEF0
        63'h04C: Data = 32'hAA0A0129;

        // 0x050: STUR X9,  [XZR, 0x28]
        63'h050: Data = 32'hF80283E9;
        // 0x054: LDUR X10, [XZR, 0x28]  // expect 0x123456789ABCDEF0
        63'h054: Data = 32'hF84283EA;

        default: Data = 32'hXXXXXXXX;
      endcase
   end
endmodule
