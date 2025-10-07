\TLV_version 1d: tl-x.org
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
   |default
      @0
         \SV_plus
            wire [B : 0] pc_plus_4;
            wire       pc_plus_4_carry;
            reg        pc_plus_4_carry_reg;
            wire [B : 0] pc_plus_4_carry_reg_wire;
            wire [B : 0] pc_plus_offset;
            wire       pc_plus_offset_carry;
            reg        pc_plus_offset_carry_reg;
            wire [B : 0] pc_plus_offset_carry_reg_wire;
            wire [B : 0] pc_plus_offset_aligned;
            wire [B : 0] plus_4;

            wire [B : 0] program_counter = o_ibus_adr[B : 0];

            wire [B : 0] new_pc;
            wire reset = i_rst;  // TL-Verilog standard reset signal

            wire [B : 0] offset_aa;
            wire [B : 0] offset_bb;

           /*  If i_iscomp=1: increment program_counter by 2 else increment program_counter by 4  */

            assign plus_4 = (W == 1) ? (i_iscomp ? i_cnt1 : i_cnt2) : (W == 4) ? ((i_cnt0 | i_cnt1) ? (i_iscomp ? 2 : 4) : 0) : 0;

            assign o_bad_pc = pc_plus_offset_aligned;

            assign {pc_plus_4_carry, pc_plus_4} = program_counter + plus_4 + pc_plus_4_carry_reg_wire;

            generate
               if (| WITH_CSR) begin : gen_csr
                  if (W == 1) begin : gen_new_pc_w_eq_1
                     assign new_pc = i_trap ? (i_csr_pc & ! (i_cnt0 || i_cnt1)) : i_jump ? pc_plus_offset_aligned : pc_plus_4;
                  end else if (W == 4) begin : gen_new_pc_w_eq_4
                     assign new_pc = i_trap ? (i_csr_pc & ((i_cnt0 || i_cnt1) ? 4'b1100 : 4'b1111)) : i_jump ? pc_plus_offset_aligned : pc_plus_4;
                  end
               end else begin : gen_no_csr
                  assign new_pc = i_jump ? pc_plus_offset_aligned : pc_plus_4;
               end
            endgenerate
            assign o_rd  = ({W{i_utype}} & pc_plus_offset_aligned) | (pc_plus_4 & {W{i_jal_or_jalr}});

            assign offset_aa = {W{i_pc_rel}} & program_counter;
            assign offset_bb = i_utype ? (i_imm & {W{i_cnt12to31}}) : i_buf;
            assign {pc_plus_offset_carry, pc_plus_offset} = offset_aa + offset_bb + pc_plus_offset_carry_reg_wire;

            generate
            if (W > 1) begin : gen_w_gt_1
               assign pc_plus_offset_aligned[B : 1] = pc_plus_offset[B : 1];
               assign pc_plus_offset_carry_reg_wire[B : 1] = {B{1'b0}};
               assign pc_plus_4_carry_reg_wire[B : 1] = {B{1'b0}};
            end
            endgenerate

            assign pc_plus_offset_aligned[0] = pc_plus_offset[0] & ! i_cnt0;
            assign pc_plus_offset_carry_reg_wire[0] = pc_plus_offset_carry_reg;
            assign pc_plus_4_carry_reg_wire[0] = pc_plus_4_carry_reg;

            initial if (RESET_STRATEGY == "NONE") o_ibus_adr = RESET_PC;

            always \@(posedge clk) begin
               pc_plus_4_carry_reg <= i_pc_en & pc_plus_4_carry;
               pc_plus_offset_carry_reg <= i_pc_en & pc_plus_offset_carry;

               if (RESET_STRATEGY == "NONE") begin
                  if (i_pc_en)
                     o_ibus_adr <= {new_pc, o_ibus_adr[31 : W]};
               end else begin
                  if (i_pc_en | reset)
                     o_ibus_adr <= reset ? RESET_PC : {new_pc, o_ibus_adr[31 : W]};
               end
            end
\SV
endmodule
