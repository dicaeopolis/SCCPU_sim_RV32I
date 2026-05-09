`include "ctrl_encode_def.v"
// data memory with byte/halfword/word access
//
// Misaligned access behavior (per RISC-V Unpriv Spec, Ch.2):
//   Byte accesses (LB/LBU/SB)    — always naturally aligned, always correct.
//   Halfword/word misaligned     — EEI-defined. This implementation requires
//     natural alignment (addr % size == 0) for LH/LHU/SH/LW/SW.
//     Misaligned halfword/word access is UNDEFINED.
//   Rationale: Rocket/BOOM trap to M-mode for SW emulation; this CPU has no
//     exception support, so misaligned behavior is left unspecified.
//
module dm(clk, DMWr, addr, din, DMType, dout);
   input          clk;
   input          DMWr;
   input  [31:0]  addr;
   input  [31:0]  din;
   input  [2:0]   DMType;
   output reg [31:0]  dout;
   
   reg [31:0] dmem[127:0];
   wire [6:0]  word_idx;
   wire [1:0]  byte_off;
   assign word_idx = addr[8:2];
   assign byte_off = addr[1:0];
   
   // write: word / halfword / byte with lane masking
   always @(posedge clk)
      if (DMWr) begin
         case (DMType)
            `dm_word: begin
               dmem[word_idx] <= din;
               $write(" memW[%h] = %h", addr, din);
            end
            `dm_halfword: begin
               if (byte_off[1])
                  dmem[word_idx][31:16] <= din[15:0];
               else
                  dmem[word_idx][15:0]  <= din[15:0];
               $write(" memH[%h] = %h", addr, din[15:0]);
            end
            `dm_byte: begin
               case (byte_off)
                  2'b00: dmem[word_idx][7:0]   <= din[7:0];
                  2'b01: dmem[word_idx][15:8]  <= din[7:0];
                  2'b10: dmem[word_idx][23:16] <= din[7:0];
                  2'b11: dmem[word_idx][31:24] <= din[7:0];
               endcase
               $write(" memB[%h] = %h", addr, din[7:0]);
            end
         endcase
      end
   
   // read: word / halfword / byte with sign/zero extension
   always @(*) begin
      case (DMType)
         `dm_word:             dout <= dmem[word_idx];
         `dm_halfword:         dout <= {{16{dmem[word_idx][byte_off[1]*16+15]}},
                                        dmem[word_idx][byte_off[1]*16 +: 16]};
         `dm_halfword_unsigned: dout <= {16'b0,
                                        dmem[word_idx][byte_off[1]*16 +: 16]};
         `dm_byte:             dout <= {{24{dmem[word_idx][byte_off*8+7]}},
                                        dmem[word_idx][byte_off*8 +: 8]};
         `dm_byte_unsigned:    dout <= {24'b0,
                                        dmem[word_idx][byte_off*8 +: 8]};
         default:              dout <= dmem[word_idx];
      endcase
   end
   
endmodule
