\m5_TLV_version 1d: tl-x.org
\m5
use(m5-1.0)

// The core logic of serv_ctrl as a reusable TLV macro.
// This macro encapsulates the program counter control logic for SERV CPU core.
\TLV serv_ctrl_logic(/_top)
   |default
      @0
         \SV_plus
            // Carry bits for PC arithmetic operations
            wire       pc_plus_4_carry;
            wire [B : 0] pc_plus_offset;
            wire       pc_plus_offset_carry;

         // Program counter increment logic
         // If i_iscomp=1: increment program_counter by 2 else increment program_counter by 4
         $plus_4[B:0] = (W == 1) ? ($i_iscomp ? $i_cnt1 : $i_cnt2) : (W == 4) ? (($i_cnt0 | $i_cnt1) ? ($i_iscomp ? 2 : 4) : 0) : 0;

         // Current program counter value
         $program_counter[B:0] = $o_ibus_adr_input[B : 0];

         // TL-Verilog standard reset signal
         $reset = $i_rst;
         
         // Compute PC + 4 (or PC + 2 for compressed instructions)
         {pc_plus_4_carry, $pc_plus_4[B:0]} = $program_counter + $plus_4 + $pc_plus_4_carry_reg_wire;

         // Next PC value selection logic
         // Priority: trap -> jump -> sequential (PC+4/PC+2)
         $new_pc[B:0] = (| WITH_CSR) ? 
                           ((W == 1) ? ($i_trap ? ($i_csr_pc & ! ($i_cnt0 || $i_cnt1)) : $i_jump ? $pc_plus_offset_aligned : $pc_plus_4) :
                            (W == 4) ? ($i_trap ? ($i_csr_pc & (($i_cnt0 || $i_cnt1) ? 4'b1100 : 4'b1111)) : $i_jump ? $pc_plus_offset_aligned : $pc_plus_4) :
                            ($i_jump ? $pc_plus_offset_aligned : $pc_plus_4)) :
                           ($i_jump ? $pc_plus_offset_aligned : $pc_plus_4);
         
         // State register updates (non-blocking assignments converted to TLV)
         <<1$pc_plus_4_carry_reg = $i_pc_en & pc_plus_4_carry;
         <<1$pc_plus_offset_carry_reg = $i_pc_en & pc_plus_offset_carry;
         
         // Carry register wire connections for different word widths
         $pc_plus_offset_carry_reg_wire = (W > 1) ?
                                            {{B{1'b0}}, $pc_plus_offset_carry_reg} :
                                            $pc_plus_offset_carry_reg;
         $pc_plus_4_carry_reg_wire = (W > 1) ?
                                       {{B{1'b0}}, $pc_plus_4_carry_reg} :
                                       $pc_plus_4_carry_reg;
         
         // Jump/branch target calculation
         $offset_aa[B:0] = {W{$i_pc_rel}} & $program_counter;  // PC-relative base
         $offset_bb[B:0] = $i_utype ? ($i_imm & {W{$i_cnt12to31}}) : $i_buf;  // Offset value
         {pc_plus_offset_carry, pc_plus_offset[B:0]} = $offset_aa + $offset_bb + $pc_plus_offset_carry_reg_wire;
         
         // Align jump target to word boundary (clear LSB for cnt0)
         $pc_plus_offset_aligned[B:0] = (W > 1) ? 
                                          {pc_plus_offset[B : 1], pc_plus_offset[0] & ! $i_cnt0} : 
                                          (pc_plus_offset[0] & ! $i_cnt0);
         
         // Output signal generation
         $o_rd_output[B:0] = ({W{$i_utype}} & $pc_plus_offset_aligned) | ($pc_plus_4 & {W{$i_jal_or_jalr}});  // Return address for JAL/JALR
         $o_bad_pc_output[B:0] = $pc_plus_offset_aligned;  // PC for exception handling

\SV
`default_nettype none
module serv_ctrl
  #(parameter RESET_STRATEGY = "MINI",
    parameter RESET_PC = 32'd0,
    parameter WITH_CSR = 1,
    parameter W = 1,
    parameter B = W-1
  )
  (
   input wire 	     clk,
   input wire 	     i_rst,
   //State
   input wire 	     i_pc_en,
   input wire 	     i_cnt12to31,
   input wire 	     i_cnt0,
   input wire        i_cnt1,
   input wire 	     i_cnt2,
   //Control
   input wire 	     i_jump,
   input wire 	     i_jal_or_jalr,
   input wire 	     i_utype,
   input wire 	     i_pc_rel,
   input wire 	     i_trap,
   input wire        i_iscomp,
   //Data
   input wire [B:0] i_imm,
   input wire [B:0] i_buf,
   input wire [B:0] i_csr_pc,
   output wire [B:0] o_rd,
   output wire [B:0] o_bad_pc,
   //External
   output reg [31:0] o_ibus_adr);
\TLV
   // Connect Verilog inputs to pipesignals
   |default
      @0
         $i_rst = *i_rst;
         $i_pc_en = *i_pc_en;
         $i_cnt12to31 = *i_cnt12to31;
         $i_cnt0 = *i_cnt0;
         $i_cnt1 = *i_cnt1;
         $i_cnt2 = *i_cnt2;
         $i_jump = *i_jump;
         $i_jal_or_jalr = *i_jal_or_jalr;
         $i_utype = *i_utype;
         $i_pc_rel = *i_pc_rel;
         $i_trap = *i_trap;
         $i_iscomp = *i_iscomp;
         $i_imm[B:0] = *i_imm;
         $i_buf[B:0] = *i_buf;
         $i_csr_pc[B:0] = *i_csr_pc;
         $o_ibus_adr_input[31:0] = *o_ibus_adr;  // Read current value for program_counter
   
   // Instantiate the core logic macro
   m5+serv_ctrl_logic(/top)
   
   // Connect TLV pipesignals to Verilog outputs
   |default
      @0
         
         \SV_plus
            // Connect pipesignals to Verilog outputs
            assign o_bad_pc = $o_bad_pc_output;
            assign o_rd = $o_rd_output;

            initial if (RESET_STRATEGY == "NONE") o_ibus_adr = RESET_PC;

            always \@(posedge clk) begin
               // Convert nested if/else to ternary expression
               o_ibus_adr <= (RESET_STRATEGY == "NONE") ?
                                (i_pc_en ? {$new_pc, o_ibus_adr[31 : W]} : o_ibus_adr) :
                                ((i_pc_en | $reset) ? 
                                   ($reset ? RESET_PC : {$new_pc, o_ibus_adr[31 : W]}) : 
                                   o_ibus_adr);
            end
\SV
endmodule
