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
         // Connect Verilog inputs:
         $ii_en = *i_en;
         $ii_cnt0 = *i_cnt0;
         $ii_sub = *i_sub;
         $ii_bool_op[1:0] = *i_bool_op;
         $ii_cmp_eq = *i_cmp_eq;
         $ii_cmp_sig = *i_cmp_sig;
         $ii_rd_sel[2:0] = *i_rd_sel;
         $ii_rs1[B:0] = *i_rs1;
         $ii_op_b[B:0] = *i_op_b;
         $ii_buf[B:0] = *i_buf;

         // ALU Operations:
         
         // Sign-extended operands for comparison
         $rrs1_sx = $ii_rs1[B] & $ii_cmp_sig;
         $op_bb_sx = $ii_op_b[B] & $ii_cmp_sig;

         // Addition/Subtraction 
         $add_bb[B:0] = $ii_op_b ^ {W{$ii_sub}};
         {$add_carry, $result_add[B:0]} = $ii_rs1 + $add_bb + $add_carry_r;

         // Comparison operations
         $result_lt = $rrs1_sx + ~ $op_bb_sx + $add_carry;
         $result_eq = ! (| $result_add) & ($cmp_reg | $ii_cnt0);
         $oo_cmp = $ii_cmp_eq ? $result_eq : $result_lt;

         // Boolean operations (XOR, OR, AND based on i_bool_op)
         /*
          The result_bool expression implements the following operations between
          i_rs1 and i_op_b depending on the value of i_bool_op:
          00 xor, 01 0, 10 or, 11 and
          i_bool_op will be 01 during shift operations, so by outputting zero under
          this condition we can safely or result_bool with i_buf
          */
         $result_bool[B:0] = (($ii_rs1 ^ $ii_op_b) & ~ {W{$ii_bool_op[0]}}) | ({W{$ii_bool_op[1]}} & $ii_op_b & $ii_rs1);

         // Set-less-than result  
         $result_slt[B:0] = (W > 1) ? {{B{1'b0}}, $cmp_reg & $ii_cnt0} : ($cmp_reg & $ii_cnt0);

         // Result multiplexing and output assignment
         $oo_rd[B:0] = $ii_buf |
                          ({W{$ii_rd_sel[0]}} & $result_add) |
                          ({W{$ii_rd_sel[1]}} & $result_slt) |
                          ({W{$ii_rd_sel[2]}} & $result_bool);

         // State register updates for next cycle
         <<1$add_carry_r[B:0] = {{B{1'b0}}, ($ii_en ? $add_carry : $ii_sub)};
         <<1$cmp_reg = $ii_en ? $oo_cmp : $cmp_reg;

         // Connect Verilog outputs:
         *o_cmp = $oo_cmp;
         *o_rd = $oo_rd;

\SV
endmodule
