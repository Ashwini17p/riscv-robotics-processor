`timescale 1ns/1ps
// ir_sync.v - two-flop synchronizer with optional polarity inversion
//
//   IR line / obstacle sensor modules are asynchronous to the CPU clock, so every
//   input goes through a 2-FF synchronizer before the logic uses it.
//   invert[i] = 1 flips the polarity of input i (for active-low sensor modules).

module ir_sync #(parameter N = 4) (
    input          clk,
    input          rst,
    input  [N-1:0] raw,
    input  [N-1:0] invert,
    output [N-1:0] sync
);

reg [N-1:0] s0, s1;

always @(posedge clk or posedge rst) begin
    if (rst) begin s0 <= {N{1'b0}}; s1 <= {N{1'b0}}; end
    else     begin s0 <= raw;       s1 <= s0;       end
end

assign sync = s1 ^ invert;

endmodule
