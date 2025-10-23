`timescale 1ns/1ps

module mux2to1_8 (
    input  wire [7:0] in0,   // Input 0
    input  wire [7:0] in1,   // Input 1
    input  wire       sel,   // Select signal
    output reg  [7:0] out    // Output
);


    // Combinational behavior; cover all sel values to avoid latches
    always @(*) begin
        case (sel)
            1'b0:   out = in0;
            1'b1:   out = in1;
            default:out = 8'h00; // handles X/Z on sel; keeps it combinational
        endcase
    end
endmodule