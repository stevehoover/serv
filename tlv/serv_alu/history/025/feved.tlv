\TLV_version 1d: tl-x.org
\SV
`default_nettype none
module serv_alu
  #(
   parameter W = 1,
   parameter B = W-1
  )
  (
   input wire 	    clk,
   //State
   input wire 	    i_en,
   input wire 	    i_cnt0,
   output wire 	    o_cmp,
   //Control
   input wire 	    i_sub,
   input wire [1:0] i_bool_op,
   input wire 	    i_cmp_eq,
   input wire 	    i_cmp_sig,
   input wire [2:0] i_rd_sel,
   //Data
   input wire  [B:0] i_rs1,
   input wire  [B:0] i_op_b,
   input wire  [B:0] i_buf,
   output wire [B:0] o_rd);

\TLV
   |default
      @0
         //Sign-extended operands
         $rrs1_sx = *i_rs1[B] & *i_cmp_sig;
         $op_bb_sx = *i_op_b[B] & *i_cmp_sig;

         $add_bb[B:0] = *i_op_b ^ {W{*i_sub}};

         {$add_carry, $result_add[B:0]} = *i_rs1 + $add_bb + $add_carry_r;

         $result_lt = $rrs1_sx + ~ $op_bb_sx + $add_carry;

         $result_eq = ! (| $result_add) & ($cmp_reg | *i_cnt0);

         *o_cmp = *i_cmp_eq ? $result_eq : $result_lt;

         /*
          The result_bool expression implements the following operations between
          i_rs1 and i_op_b depending on the value of i_bool_op

          00 xor
          01 0
          10 or
          11 and

          i_bool_op will be 01 during shift operations, so by outputting zero under
          this condition we can safely or result_bool with i_buf
          */
         $result_bool[B:0] = ((*i_rs1 ^ *i_op_b) & ~ {W{*i_bool_op[0]}}) | ({W{*i_bool_op[1]}} & *i_op_b & *i_rs1);

         $result_slt[B:0] = (W > 1) ? {{B{1'b0}}, $cmp_reg & *i_cnt0} : ($cmp_reg & *i_cnt0);

         *o_rd = *i_buf |
                          ({W{*i_rd_sel[0]}} & $result_add) |
                          ({W{*i_rd_sel[1]}} & $result_slt) |
                          ({W{*i_rd_sel[2]}} & $result_bool);

         <<1$add_carry_r[B:0] = {{B{1'b0}}, (*i_en ? $add_carry : *i_sub)};

         <<1$cmp_reg = *i_en ? *o_cmp : $cmp_reg;

\SV
endmodule
