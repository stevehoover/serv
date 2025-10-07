\TLV_version 1d: tl-x.org
\SV
/* Copyright lowRISC contributors.
Copyright 2018 ETH Zurich and University of Bologna, see also CREDITS.md.
Licensed under the Apache License, Version 2.0, see LICENSE for details.
SPDX-License-Identifier: Apache-2.0

* Adapted to SERV by @Abdulwadoodd as part of the project under spring '22 LFX Mentorship program */

/* Decodes RISC-V compressed instructions into their RV32i equivalent. */

module serv_compdec
  (
   input wire i_clk,
   input  wire [31 : 0] i_instr,
   input  wire i_ack,
   output wire [31 : 0] o_instr,
   output reg o_iscomp);
\TLV
   |default
      @0
         // Connect Verilog inputs to TLV pipesignals
         $instr[31:0] = *i_instr;
         
         \SV_plus
            localparam OPCODE_LOAD     = 7'h03;
            localparam OPCODE_OP_IMM   = 7'h13;
            localparam OPCODE_STORE    = 7'h23;
            localparam OPCODE_OP       = 7'h33;
            localparam OPCODE_LUI      = 7'h37;
            localparam OPCODE_BRANCH   = 7'h63;
            localparam OPCODE_JALR     = 7'h67;
            localparam OPCODE_JAL      = 7'h6f;

            // Clock assignment for TL-Verilog
            wire clk;
            assign clk = i_clk;

            assign o_instr = $illegal_instr ? i_instr : $comp_instr;

            always @(posedge clk) begin
               if(i_ack)
                  o_iscomp <= ! $illegal_instr;
            end

         // Combinational logic moved to TLV context
         // Determine if instruction is illegal
         $illegal_instr = ($instr[1:0] == 2'b11) ? 1'b1 :                          // Uncompressed instruction
                          ($instr[1:0] == 2'b00 && $instr[15:14] == 2'b10) ? 1'b1 : // C0 invalid case  
                          1'b0;                                                         // Default: legal

         // Convert main case statement to ternary assignment
         $comp_instr[31:0] = 
               ($instr[1 : 0] == 2'b00) ?
                  // C0 compressed instructions
                  ($instr[15 : 14] == 2'b00) ?
                     // c.addi4spn -> addi rd', x2, imm
                     {2'b0, $instr[10 : 7], $instr[12 : 11], $instr[5],
                               $instr[6], 2'b00, 5'h02, 3'b000, 2'b01, $instr[4 : 2], {OPCODE_OP_IMM}} :
                  ($instr[15 : 14] == 2'b01) ?
                     // c.lw -> lw rd', imm(rs1')
                     {5'b0, $instr[5], $instr[12 : 10], $instr[6],
                               2'b00, 2'b01, $instr[9 : 7], 3'b010, 2'b01, $instr[4 : 2], {OPCODE_LOAD}} :
                  ($instr[15 : 14] == 2'b11) ?
                     // c.sw -> sw rs2', imm(rs1')
                     {5'b0, $instr[5], $instr[12], 2'b01, $instr[4 : 2],
                               2'b01, $instr[9 : 7], 3'b010, $instr[11 : 10], $instr[6],
                               2'b00, {OPCODE_STORE}} :
                     // 2'b10 - C0 invalid case, retain default instruction
                     $instr :

               ($instr[1 : 0] == 2'b01) ?
                  // C1 compressed instructions
                  // Register address checks for RV32E are performed in the regular instruction decoder.
                  ($instr[15 : 13] == 3'b000) ?
                     // c.addi -> addi rd, rd, nzimm / c.nop
                     {{6 {$instr[12]}}, $instr[12], $instr[6 : 2],
                               $instr[11 : 7], 3'b0, $instr[11 : 7], {OPCODE_OP_IMM}} :
                  (($instr[15 : 13] == 3'b001) || ($instr[15 : 13] == 3'b101)) ?
                     // 001: c.jal -> jal x1, imm / 101: c.j -> jal x0, imm
                     {$instr[12], $instr[8], $instr[10 : 9], $instr[6],
                               $instr[7], $instr[2], $instr[11], $instr[5 : 3],
                               {9 {$instr[12]}}, 4'b0, ~ $instr[15], {OPCODE_JAL}} :
                  ($instr[15 : 13] == 3'b010) ?
                     // c.li -> addi rd, x0, nzimm (c.li hints are translated into an addi hint)
                     {{6 {$instr[12]}}, $instr[12], $instr[6 : 2], 5'b0,
                               3'b0, $instr[11 : 7], {OPCODE_OP_IMM}} :
                  ($instr[15 : 13] == 3'b011) ?
                     // c.lui/c.addi16sp ternary
                     ($instr[11 : 7] == 5'h02) ?
                        // c.addi16sp -> addi x2, x2, nzimm
                        {{3 {$instr[12]}}, $instr[4 : 3], $instr[5], $instr[2],
                                  $instr[6], 4'b0, 5'h02, 3'b000, 5'h02, {OPCODE_OP_IMM}} :
                        // c.lui -> lui rd, imm (c.lui hints are translated into a lui hint)
                        {{15 {$instr[12]}}, $instr[6 : 2], $instr[11 : 7], {OPCODE_LUI}} :
                  ($instr[15 : 13] == 3'b100) ?
                     // Complex nested ternary for shift/logic operations
                     (($instr[11 : 10] == 2'b00) || ($instr[11 : 10] == 2'b01)) ?
                        // 00: c.srli -> srli rd, rd, shamt / 01: c.srai -> srai rd, rd, shamt
                        {1'b0, $instr[10], 5'b0, $instr[6 : 2], 2'b01, $instr[9 : 7],
                                  3'b101, 2'b01, $instr[9 : 7], {OPCODE_OP_IMM}} :
                     ($instr[11 : 10] == 2'b10) ?
                        // c.andi -> andi rd, rd, imm
                        {{6 {$instr[12]}}, $instr[12], $instr[6 : 2], 2'b01, $instr[9 : 7],
                                  3'b111, 2'b01, $instr[9 : 7], {OPCODE_OP_IMM}} :
                        // 2'b11: Nested ternary for c.sub/c.xor/c.or/c.and
                        ($instr[6 : 5] == 2'b00) ?
                           // c.sub -> sub rd', rd', rs2'
                           {2'b01, 5'b0, 2'b01, $instr[4 : 2], 2'b01, $instr[9 : 7],
                                         3'b000, 2'b01, $instr[9 : 7], {OPCODE_OP}} :
                        ($instr[6 : 5] == 2'b01) ?
                           // c.xor -> xor rd', rd', rs2'
                           {7'b0, 2'b01, $instr[4 : 2], 2'b01, $instr[9 : 7], 3'b100,
                                     2'b01, $instr[9 : 7], {OPCODE_OP}} :
                        ($instr[6 : 5] == 2'b10) ?
                           // c.or -> or rd', rd', rs2'
                           {7'b0, 2'b01, $instr[4 : 2], 2'b01, $instr[9 : 7], 3'b110,
                                     2'b01, $instr[9 : 7], {OPCODE_OP}} :
                           // c.and -> and rd', rd', rs2'
                           {7'b0, 2'b01, $instr[4 : 2], 2'b01, $instr[9 : 7], 3'b111,
                                     2'b01, $instr[9 : 7], {OPCODE_OP}} :
                  // 110/111: c.beqz/c.bnez -> beq/bne rs1', x0, imm
                  {{4 {$instr[12]}}, $instr[6 : 5], $instr[2], 5'b0, 2'b01,
                           $instr[9 : 7], 2'b00, $instr[13], $instr[11 : 10], $instr[4 : 3],
                           $instr[12], {OPCODE_BRANCH}} :

               ($instr[1 : 0] == 2'b10) ?
                  // C2 compressed instructions
                  // Register address checks for RV32E are performed in the regular instruction decoder.
                  // If this check fails, an illegal instruction exception is triggered and the controller
                  // writes the actual faulting instruction to mtval.
                  ($instr[15 : 14] == 2'b00) ?
                     // c.slli -> slli rd, rd, shamt (c.slli hints are translated into a slli hint)
                     {7'b0, $instr[6 : 2], $instr[11 : 7], 3'b001, $instr[11 : 7], {OPCODE_OP_IMM}} :
                  ($instr[15 : 14] == 2'b01) ?
                     // c.lwsp -> lw rd, imm(x2)
                     {4'b0, $instr[3 : 2], $instr[12], $instr[6 : 4], 2'b00, 5'h02,
                               3'b010, $instr[11 : 7], {OPCODE_LOAD}} :
                  ($instr[15 : 14] == 2'b10) ?
                     // Complex nested ternary for c.mv/c.jr/c.add/c.jalr/c.ebreak
                     ($instr[12] == 1'b0) ?
                        ($instr[6 : 2] != 5'b0) ?
                           // c.mv -> add rd/rs1, x0, rs2 (c.mv hints are translated into an add hint)
                           {7'b0, $instr[6 : 2], 5'b0, 3'b0, $instr[11 : 7], {OPCODE_OP}} :
                           // c.jr -> jalr x0, rd/rs1, 0
                           {12'b0, $instr[11 : 7], 3'b0, 5'b0, {OPCODE_JALR}} :
                        ($instr[6 : 2] != 5'b0) ?
                           // c.add -> add rd, rd, rs2 (c.add hints are translated into an add hint)
                           {7'b0, $instr[6 : 2], $instr[11 : 7], 3'b0, $instr[11 : 7], {OPCODE_OP}} :
                           ($instr[11 : 7] == 5'b0) ?
                              // c.ebreak -> ebreak
                              32'h00_10_00_73 :
                              // c.jalr -> jalr x1, rs1, 0
                              {12'b0, $instr[11 : 7], 3'b000, 5'b00001, {OPCODE_JALR}} :
                     // c.swsp -> sw rs2, imm(x2)
                     {4'b0, $instr[8 : 7], $instr[12], $instr[6 : 2], 5'h02, 3'b010,
                               $instr[11 : 9], 2'b00, {OPCODE_STORE}} :

               // Incoming instruction is not compressed (2'b11)
               $instr;

\SV
endmodule
